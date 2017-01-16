import Html exposing (Html)
import Html.Attributes exposing (classList)
import Time exposing (Time, second)
import Date exposing (Date)
import Debug exposing (log)

main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

type alias Model = Time

init : (Model, Cmd Msg)
init =
  (0, Cmd.none)

type Msg
  = Tick Time

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Tick newTime ->
      (newTime, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Time.every second Tick

view : Model -> Html Msg
view model =
  let
      date =
        Date.fromTime model

      hour =
        Date.hour date

      minute =
        Date.minute date

      second =
        Date.second date

      fullClock =
        twoDigitsFormat (hour) ++ ":" ++ twoDigitsFormat (minute) ++ ":" ++ twoDigitsFormat (second)

      latitude = -6.1744444
      longitude = 106.8294444
      elevation = 0
      timeZone = toFloat 7
      prayTimes =
        calculatePrayTimes latitude longitude elevation timeZone date
      adjustedTime =
        adjustTimes longitude timeZone prayTimes
      formattedTimes =
        formatTimes adjustedTime
      htmlTimeList =
        [ ("Subuh", formattedTimes.fajr)
        , ("Terbit", formattedTimes.sunRise)
        , ("Zuhur", formattedTimes.dhuhr)
        , ("Ashar", formattedTimes.asr)
        , ("Magrib", formattedTimes.magrib)
        , ("Isya", formattedTimes.isya)
        ]
      htmlTimeStructure (label, time) =
        Html.div
        [ classList [ ("time__shalat", True) ] ]
        [ Html.div
          [ classList [ ("time__label", True) ] ]
          [ Html.text (label) ]
        , Html.div
          [ classList [ ("time__shalat-time", True) ] ]
          [ Html.text (time) ]
        ]

      htmlClock clock =
        Html.div
        [ classList [ ("time__clock", True) ] ]
        [ Html.h1 [] [ Html.text (clock) ] ]

      htmlTimeKeeper =
        ([ htmlClock (fullClock) ]) ++ (List.map htmlTimeStructure htmlTimeList)


  in
     Html.div [ classList [ ("time", True) ] ] htmlTimeKeeper

type alias PrayTimes =
  { fajr: Float
  , sunRise: Float
  , dhuhr: Float
  , asr: Float
  , magrib: Float
  , isya: Float
  }

calculatePrayTimes latitude longitude elevation timeZone date =
  let
      julianDate =
        julianDateByCoordinate longitude (toJulianDate date)
      fajrTime =
        sunAngleTime latitude 20 julianDate 0.20833333333333334 CCW
      sunRiseTime =
        sunAngleTime latitude (riseSetAngle (elevation)) julianDate 0.25 CCW
      dhuhrTime =
        midDayTime julianDate 0.5
      asrTime =
        calcAsrTime latitude 1 julianDate 0.5416666666666666
      magribTime =
        sunAngleTime latitude 1 julianDate 0.75 None
      isyaTime =
        sunAngleTime latitude 18 julianDate 0.75 None
  in
     { fajr = fajrTime
     , sunRise = sunRiseTime
     , dhuhr = dhuhrTime
     , asr = asrTime
     , magrib = magribTime
     , isya = isyaTime
     }


type alias FormattedPrayTimes =
  { fajr: String
  , sunRise: String
  , dhuhr: String
  , asr: String
  , magrib: String
  , isya: String
  }

formatTimes : PrayTimes -> FormattedPrayTimes
formatTimes prayTimes =
  { fajr    = formatTime prayTimes.fajr
  , sunRise = formatTime prayTimes.sunRise
  , dhuhr   = formatTime prayTimes.dhuhr
  , asr     = formatTime prayTimes.asr
  , magrib  = formatTime prayTimes.magrib
  , isya    = formatTime prayTimes.isya
  }

formatTime time =
  let
      roundedTime = fixHour (time + (0.5 / 60))
      hours = floor (roundedTime)
      minutes = floor ((roundedTime - toFloat (hours)) * 60)
  in
     twoDigitsFormat (hours) ++ ":" ++ twoDigitsFormat (minutes)

twoDigitsFormat : Int -> String
twoDigitsFormat number =
  if number < 10 then
     "0" ++ toString (number)
  else
     toString (number)

adjustTimes : Float -> Float -> PrayTimes -> PrayTimes
adjustTimes longitude timeZone {fajr,sunRise,dhuhr,asr,magrib,isya} =
  let
      fajrTime =
        fajr + timeZone - (longitude / 15) + (2 / 60)
      sunRiseTime =
        sunRise + timeZone - (longitude / 15) + (-2 / 60)
      dhuhrTime =
        (dhuhr + timeZone - (longitude / 15)) + (2 / 60)
      asrTime =
        (asr + timeZone - (longitude / 15)) + (2 / 60)
      magribTime =
        (magrib + timeZone - (longitude / 15)) + (2 / 60)
      isyaTime =
        (isya + timeZone - (longitude / 15)) + (2 / 60)
  in
     { fajr = fajrTime
     , sunRise = sunRiseTime
     , dhuhr = dhuhrTime
     , asr = asrTime
     , magrib = magribTime
     , isya = isyaTime
     }

type Direction
  = CCW
  | CW
  | None

calcAsrTime : Float -> Float -> Float -> Float -> Float
calcAsrTime latitude factor julianDate time =
  let
      sunPositionAtTime = sunPosition (julianDate + time)
      declination = sunPositionAtTime.declination
      absLatDec = (abs (latitude - declination))
      degreeTan = (tan ((absLatDec * pi) / 180))
      angle = (-1 * ((atan (1 / (factor + degreeTan)) * 180) / pi))
  in
     sunAngleTime latitude angle julianDate time None


sunAngleTime : Float -> Float -> Float -> Float -> Direction -> Float
sunAngleTime latitude angle julianDate time direction =
  let
      sunPositionAtTime = sunPosition (julianDate + time)
      declination = (sunPositionAtTime.declination)
      noon = (midDayTime julianDate time)
      angleVar = (angle)
      degreeA = (-1 * sin (angleVar * pi / 180))
      degreeSinD = (sin (declination * pi / 180))
      degreeSinL = (sin (latitude * pi / 180))
      degreeCosD = (cos (declination * pi / 180))
      degreeCosL = (cos (latitude * pi / 180))
      beforeArcCos = ((degreeA - degreeSinD * degreeSinL) / (degreeCosD * degreeCosL))
      tVar = (1 / 15 * ((acos beforeArcCos) * 180 / pi))
  in
     case direction of
       CCW -> (noon + (-1 * tVar))
       _ -> (noon + tVar)

midDayTime : Float -> Float -> Float
midDayTime julianDate time =
  let
      sunPositionDhuhr = sunPosition (julianDate + time)
      equationOfTime = sunPositionDhuhr.equation
  in
     fixHour (12 - equationOfTime)

riseSetAngle : Float -> Float
riseSetAngle elevation =
  let
      angle = 0.0347 * (sqrt (elevation))
  in
     0.833 + angle

monthToInt : Date.Month -> Int
monthToInt month =
  case month of
    Date.Jan -> 1
    Date.Feb -> 2
    Date.Mar -> 3
    Date.Apr -> 4
    Date.May -> 5
    Date.Jun -> 6
    Date.Jul -> 7
    Date.Aug -> 8
    Date.Sep -> 9
    Date.Oct -> 10
    Date.Nov -> 11
    Date.Dec -> 12

julianDateByCoordinate : Float -> Float -> Float
julianDateByCoordinate longitude julianDate =
  julianDate - (longitude / (15 * 24))

toJulianDate : Date -> Float
toJulianDate date =
  let
      year = Date.year date

      month = monthToInt (Date.month date)

      day = Date.day date

      julianYear =
        if month <= 2 then
          year - 1
        else
          year

      julianMonth =
        if month <= 2 then
          month + 12
        else
          month

      aVar =
        floor (toFloat (julianYear) / 100)

      bVar =
        2 - aVar + floor (toFloat (aVar) / 4)

  in
     toFloat (floor (365.25 * toFloat (julianYear + 4716)) + floor (30.6001 * toFloat (julianMonth + 1))) + toFloat day + toFloat bVar - 1524.5

type alias SunPosition = { declination: Float, equation: Float }

sunPosition : Float -> SunPosition
sunPosition julianDate =
  let
      numberOfDays = julianDate - 2451545.0

      meanAnomaly =
        fixAngle (357.529 + (0.98560028 * numberOfDays))

      meanLongitude =
        fixAngle (280.459 + (0.98564736 * numberOfDays))

      eclipticLongitude =
        let
            x =
              1.915 * (sin (degrees (meanAnomaly)))
            y =
              0.020 * (sin (degrees (2 * meanAnomaly)))
        in
           fixAngle (meanLongitude + x + y)

      distanceOfSun =
        1.00014 - (0.01671 * cos (degrees (meanAnomaly))) - (0.00014 * cos (degrees (2 * meanAnomaly)))

      obliquityOfTheElliptic =
        23.439 - (0.00000036 * numberOfDays)

      angularCorrection =
        let
            y =
              cos (degrees (obliquityOfTheElliptic)) * sin (degrees (eclipticLongitude))
            x =
              cos (degrees (eclipticLongitude))
            arctan2 =
              ((atan2 y x) * 180.0) / pi
        in
           arctan2 / 15.0

      equation =
        meanLongitude / 15.0 - fixHour (angularCorrection)

      declination =
        (asin (sin (degrees (obliquityOfTheElliptic)) * sin (degrees (eclipticLongitude)))) * 180 / pi
  in
     { declination = declination, equation = equation }

fix : Float -> Float -> Float
fix a b =
  let
      aVar = a - (b * toFloat (floor (a / b)))
  in
     if aVar < 0 then
       aVar + b
     else
       aVar


fixAngle : Float -> Float
fixAngle a =
  fix a 360.0


fixHour : Float -> Float
fixHour a =
  fix a 24.0

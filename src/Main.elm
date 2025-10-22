port module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes exposing (classList, style)
import Html.Events exposing (onClick)
import Time exposing (Posix)
import Task
import PrayTime exposing (..)


-- Ports for geolocation
port requestLocation : () -> Cmd msg


port receiveLocation : (LatLong -> msg) -> Sub msg


type alias Flags =
    { testIqomah : Maybe String
    , testOffset : Int
    }


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias LatLong =
    { latitude : Float
    , longitude : Float
    }


type alias Model =
    { time : Posix
    , zone : Time.Zone
    , location : LatLong
    , testMode : Maybe String
    , testOffset : Int
    , initialTime : Maybe Posix
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { time = Time.millisToPosix 0
      , zone = Time.utc
      , location =
            { latitude = -6.2276252
            , longitude = 106.7947417
            }
      , testMode = flags.testIqomah
      , testOffset = flags.testOffset
      , initialTime = Nothing
      }
    , Cmd.batch
        [ Task.perform Tick Time.now
        , Task.perform AdjustTimeZone Time.here
        ]
    )


type Msg
    = Tick Posix
    | AdjustTimeZone Time.Zone
    | RequestLocation
    | ReceiveLocation LatLong


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            let
                updatedInitialTime =
                    case model.initialTime of
                        Nothing ->
                            Just newTime

                        Just _ ->
                            model.initialTime
            in
            ( { model | time = newTime, initialTime = updatedInitialTime }, Cmd.none )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }, Cmd.none )

        RequestLocation ->
            ( model, requestLocation () )

        ReceiveLocation newLocation ->
            ( { model | location = newLocation }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every 1000 Tick
        , receiveLocation ReceiveLocation
        ]


view : Model -> Html Msg
view model =
    let
        baseHour =
            Time.toHour model.zone model.time

        baseMinute =
            Time.toMinute model.zone model.time

        baseSecond =
            Time.toSecond model.zone model.time

        day =
            Time.toDay model.zone model.time

        month =
            Time.toMonth model.zone model.time
                |> monthToNumber

        year =
            Time.toYear model.zone model.time

        latitude =
            model.location.latitude

        longitude =
            model.location.longitude

        elevation =
            0

        timeZone =
            7

        -- Calculate prayer times first (needed for test mode)
        basePrayerTimesList =
            calculatePrayTimes latitude longitude elevation timeZone
                { year = year, month = month, day = day, hour = baseHour, minute = baseMinute, second = baseSecond }
                |> adjustTimes longitude timeZone
                |> formatTimes
                |> toTimeList

        -- Calculate elapsed seconds for test mode ticking
        elapsedSeconds =
            case model.initialTime of
                Just initialPosix ->
                    (Time.posixToMillis model.time - Time.posixToMillis initialPosix) // 1000

                Nothing ->
                    0

        -- Override time if in test mode
        ( hour, minute, second ) =
            case model.testMode of
                Just prayerName ->
                    getTestTime basePrayerTimesList prayerName model.testOffset elapsedSeconds

                Nothing ->
                    ( baseHour, baseMinute, baseSecond )

        -- Create time info for display
        timeInfo =
            { year = year
            , month = month
            , day = day
            , hour = hour
            , minute = minute
            , second = second
            }

        prayerTimesList =
            basePrayerTimesList

        htmlTimes =
            prayerTimesList
                |> List.map htmlTimeStructure

        htmlClock =
            formattedTime hour minute second
                |> toHtmlClock

        htmlIqomah =
            htmlIqomahCountdown timeInfo prayerTimesList

        testModeIndicator =
            case model.testMode of
                Just prayerName ->
                    Html.div
                        [ classList [ ( "test-mode-indicator", True ) ]
                        , style "background-color" "#ff6b6b"
                        , style "color" "white"
                        , style "padding" "10px"
                        , style "margin" "10px 0"
                        , style "border-radius" "5px"
                        , style "font-weight" "bold"
                        , style "text-align" "center"
                        ]
                        [ Html.text ("TEST MODE: " ++ String.toUpper prayerName ++ " + " ++ String.fromInt model.testOffset ++ " min") ]

                Nothing ->
                    Html.div [] []

        locationButton =
            Html.button
                [ onClick RequestLocation
                , classList [ ( "time__location-button", True ) ]
                ]
                [ Html.text "Cek Lokasi" ]

        htmlTimeKeeper =
            [ htmlClock, testModeIndicator, htmlIqomah ] ++ htmlTimes ++ [ locationButton ]
    in
    Html.div [ classList [ ( "time", True ) ] ] htmlTimeKeeper


monthToNumber : Time.Month -> Int
monthToNumber month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


formattedTime : Int -> Int -> Int -> String
formattedTime hour minute second =
    twoDigitsFormat hour ++ ":" ++ twoDigitsFormat minute ++ ":" ++ twoDigitsFormat second


toHtmlClock : String -> Html msg
toHtmlClock clock =
    Html.div
        [ classList [ ( "time__clock", True ) ] ]
        [ Html.h1 [] [ Html.text clock ] ]


htmlTimeStructure : ( String, String ) -> Html msg
htmlTimeStructure ( label, time ) =
    Html.div
        [ classList [ ( "time__shalat", True ) ] ]
        [ Html.div
            [ classList [ ( "time__label", True ) ] ]
            [ Html.text label ]
        , Html.div
            [ classList [ ( "time__shalat-time", True ) ] ]
            [ Html.text time ]
        ]


-- Iqomah countdown functions
type alias TimeInfo =
    { year : Int
    , month : Int
    , day : Int
    , hour : Int
    , minute : Int
    , second : Int
    }


-- Test mode helper function
getTestTime : List ( String, String ) -> String -> Int -> Int -> ( Int, Int, Int )
getTestTime prayerTimes prayerName offsetMinutes elapsedSeconds =
    let
        normalizedName =
            String.toLower prayerName

        matchingPrayer =
            prayerTimes
                |> List.filter (\( name, _ ) -> String.toLower name == normalizedName)
                |> List.head

        defaultTime =
            ( 12, 0, 30 )
    in
    case matchingPrayer of
        Just ( _, timeStr ) ->
            let
                parts =
                    String.split ":" timeStr

                hours =
                    parts
                        |> List.head
                        |> Maybe.withDefault "0"
                        |> String.toInt
                        |> Maybe.withDefault 0

                minutes =
                    parts
                        |> List.drop 1
                        |> List.head
                        |> Maybe.withDefault "0"
                        |> String.toInt
                        |> Maybe.withDefault 0

                -- Calculate base time: prayer time + offset minutes + elapsed seconds
                totalSeconds =
                    (hours * 3600) + (minutes * 60) + (offsetMinutes * 60) + elapsedSeconds

                newHour =
                    modBy 24 (totalSeconds // 3600)

                newMinute =
                    modBy 60 ((totalSeconds // 60))

                newSecond =
                    modBy 60 totalSeconds
            in
            ( newHour, newMinute, newSecond )

        Nothing ->
            defaultTime


timeStringToSeconds : String -> Int
timeStringToSeconds timeStr =
    let
        parts =
            String.split ":" timeStr

        hours =
            parts
                |> List.head
                |> Maybe.withDefault "0"
                |> String.toInt
                |> Maybe.withDefault 0

        minutes =
            parts
                |> List.drop 1
                |> List.head
                |> Maybe.withDefault "0"
                |> String.toInt
                |> Maybe.withDefault 0
    in
    (hours * 3600) + (minutes * 60)


timeInfoToSeconds : TimeInfo -> Int
timeInfoToSeconds timeInfo =
    (timeInfo.hour * 3600) + (timeInfo.minute * 60) + timeInfo.second


findIqomahStatus : TimeInfo -> List ( String, String ) -> Maybe ( String, Int )
findIqomahStatus timeInfo prayerTimes =
    let
        currentSeconds =
            timeInfoToSeconds timeInfo

        iqomahDuration =
            5 * 60

        checkPrayer ( name, timeStr ) =
            if name == "Terbit" then
                Nothing

            else
                let
                    prayerSeconds =
                        timeStringToSeconds timeStr

                    secondsSincePrayer =
                        currentSeconds - prayerSeconds

                    remainingSeconds =
                        iqomahDuration - secondsSincePrayer
                in
                if secondsSincePrayer >= 0 && secondsSincePrayer < iqomahDuration then
                    Just ( name, remainingSeconds )

                else
                    Nothing

        results =
            List.filterMap checkPrayer prayerTimes
    in
    List.head results


formatIqomahTime : Int -> String
formatIqomahTime seconds =
    let
        mins =
            seconds // 60

        secs =
            modBy 60 seconds
    in
    String.fromInt mins ++ " min " ++ String.fromInt secs ++ " sec"


htmlIqomahCountdown : TimeInfo -> List ( String, String ) -> Html msg
htmlIqomahCountdown timeInfo prayerTimes =
    case findIqomahStatus timeInfo prayerTimes of
        Just ( prayerName, remainingSeconds ) ->
            Html.div
                [ classList [ ( "time__iqomah", True ) ] ]
                [ Html.div
                    [ classList [ ( "time__iqomah-label", True ) ] ]
                    [ Html.text ("Iqomah " ++ prayerName) ]
                , Html.div
                    [ classList [ ( "time__iqomah-countdown", True ) ] ]
                    [ Html.text (formatIqomahTime remainingSeconds) ]
                ]

        Nothing ->
            Html.div [] []

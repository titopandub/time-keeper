port module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes exposing (classList)
import Html.Events exposing (onClick)
import Time exposing (Posix)
import Task
import PrayTime exposing (..)


-- Ports for geolocation
port requestLocation : () -> Cmd msg


port receiveLocation : (LatLong -> msg) -> Sub msg


main : Program () Model Msg
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
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { time = Time.millisToPosix 0
      , zone = Time.utc
      , location =
            { latitude = -6.2276252
            , longitude = 106.7947417
            }
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
            ( { model | time = newTime }, Cmd.none )

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
        hour =
            Time.toHour model.zone model.time

        minute =
            Time.toMinute model.zone model.time

        second =
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

        -- Create time info for prayer calculation
        timeInfo =
            { year = year
            , month = month
            , day = day
            , hour = hour
            , minute = minute
            , second = second
            }

        prayerTimesList =
            calculatePrayTimes latitude longitude elevation timeZone timeInfo
                |> adjustTimes longitude timeZone
                |> formatTimes
                |> toTimeList

        htmlTimes =
            prayerTimesList
                |> List.map htmlTimeStructure

        htmlClock =
            formattedTime hour minute second
                |> toHtmlClock

        htmlIqomah =
            htmlIqomahCountdown timeInfo prayerTimesList

        locationButton =
            Html.button
                [ onClick RequestLocation
                , classList [ ( "time__location-button", True ) ]
                ]
                [ Html.text "Cek Lokasi" ]

        htmlTimeKeeper =
            [ htmlClock, htmlIqomah ] ++ htmlTimes ++ [ locationButton ]
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

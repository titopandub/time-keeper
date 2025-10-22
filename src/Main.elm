module Main exposing (..)

import Html exposing (Html)
import Html.Attributes exposing (classList)
import Html.Events exposing (onClick)
import Time exposing (Time, second)
import Date exposing (Date)
import Task exposing (Task)
import Geolocation exposing (Location)
import Debug exposing (log)
import PrayTime exposing (..)


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

type alias LatLong =
    { latitude: Float
    , longitude: Float
    }

type alias Model =
    ( { time: Time
      , location: LatLong
      }
    )


init : ( Model, Cmd Msg )
init =
    let
        batch =
            [ Task.perform Tick Time.now ]
    in
        ( { time = 0
        , location = { latitude = -6.2276252
        , longitude = 106.7947417 } }
        , Cmd.batch batch )


type Msg
    = Tick Time
    | LookupLocation
    | Success Location
    | Failure Geolocation.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            ( { model | time = newTime }, Cmd.none )
        LookupLocation ->
            ( model, Task.attempt processLocation Geolocation.now )
        Success location ->
            let
                newLocation =
                    { latitude = location.latitude
                    , longitude = location.longitude
                    }
            in
                ( { model | location = newLocation }
                , Cmd.none )
        Failure message ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every second Tick


view : Model -> Html Msg
view model =
    let
        date =
            Date.fromTime model.time

        latitude =
            model.location.latitude

        longitude =
            model.location.longitude

        elevation =
            0

        timeZone =
            toFloat 7

        prayerTimesList =
            date
                |> calculatePrayTimes latitude longitude elevation timeZone
                |> adjustTimes longitude timeZone
                |> formatTimes
                |> toTimeList

        htmlTimes =
            prayerTimesList
                |> List.map htmlTimeStructure

        htmlClock =
            date
                |> formattedDate
                |> toHtmlClock

        htmlIqomah =
            htmlIqomahCountdown date prayerTimesList

        htmlTimeKeeper =
            ([ htmlClock, htmlIqomah ]) ++ (htmlTimes) ++ buttonGeolocation
    in
        Html.div [ classList [ ( "time", True ) ] ] htmlTimeKeeper


formattedDate : Date -> String
formattedDate date =
    let
        hour =
            Date.hour date

        minute =
            Date.minute date

        second =
            Date.second date
    in
        twoDigitsFormat (hour) ++ ":" ++ twoDigitsFormat (minute) ++ ":" ++ twoDigitsFormat (second)


toHtmlClock : String -> Html msg
toHtmlClock clock =
    Html.div
        [ classList [ ( "time__clock", True ) ] ]
        [ Html.h1 [] [ Html.text (clock) ] ]

htmlTimeStructure : ( String, String ) -> Html msg
htmlTimeStructure ( label, time ) =
    Html.div
        [ classList [ ( "time__shalat", True ) ] ]
        [ Html.div
            [ classList [ ( "time__label", True ) ] ]
            [ Html.text (label) ]
        , Html.div
            [ classList [ ( "time__shalat-time", True ) ] ]
            [ Html.text (time) ]
        ]

processLocation : Result Geolocation.Error Location -> Msg
processLocation result =
    case result of
        Ok location ->
            Success location
        Err message ->
            Failure message

buttonGeolocation =
    [ Html.button
        [ onClick LookupLocation
        , classList [ ("time__location-button", True) ]
        ]
        [ Html.text "Cek Lokasi" ] ]


-- Iqomah countdown functions
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
                |> Result.withDefault 0

        minutes =
            parts
                |> List.drop 1
                |> List.head
                |> Maybe.withDefault "0"
                |> String.toInt
                |> Result.withDefault 0
    in
        (hours * 3600) + (minutes * 60)


dateToSeconds : Date -> Int
dateToSeconds date =
    let
        hours =
            Date.hour date

        minutes =
            Date.minute date

        seconds =
            Date.second date
    in
        (hours * 3600) + (minutes * 60) + seconds


findIqomahStatus : Date -> List ( String, String ) -> Maybe ( String, Int )
findIqomahStatus date prayerTimes =
    let
        currentSeconds =
            dateToSeconds date

        iqomahDuration =
            5 * 60  -- 5 minutes in seconds

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
        (toString mins) ++ " min " ++ (toString secs) ++ " sec"


htmlIqomahCountdown : Date -> List ( String, String ) -> Html msg
htmlIqomahCountdown date prayerTimes =
    case findIqomahStatus date prayerTimes of
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

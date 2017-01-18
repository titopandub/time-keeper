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
        , location = { latitude = -6.1744444
        , longitude = 106.8294444 } }
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

        htmlTimes =
            date
                |> calculatePrayTimes latitude longitude elevation timeZone
                |> adjustTimes longitude timeZone
                |> formatTimes
                |> toTimeList
                |> List.map htmlTimeStructure

        htmlClock =
            date
                |> formattedDate
                |> toHtmlClock

        htmlTimeKeeper =
            ([ htmlClock ]) ++ (htmlTimes) ++ buttonGeolocation
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

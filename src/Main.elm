import Html exposing (Html)
import Html.Attributes exposing (classList)
import Time exposing (Time, second)
import Date exposing (Date)
import Debug exposing (log)
import PrayTime exposing (..)

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
      date = Date.fromTime model
      latitude = -6.1744444
      longitude = 106.8294444
      elevation = 0
      timeZone = toFloat 7
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
        ([ htmlClock ]) ++ (htmlTimes)

  in
     Html.div [ classList [ ("time", True) ] ] htmlTimeKeeper


formattedDate : Date -> String
formattedDate date =
  let
      hour = Date.hour date
      minute = Date.minute date
      second = Date.second date
  in
     twoDigitsFormat (hour) ++ ":" ++ twoDigitsFormat (minute) ++ ":" ++ twoDigitsFormat (second)

toHtmlClock : String -> Html msg
toHtmlClock clock =
  Html.div
  [ classList [ ("time__clock", True) ] ]
  [ Html.h1 [] [ Html.text (clock) ] ]

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


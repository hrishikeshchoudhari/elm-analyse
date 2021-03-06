module Client.Main exposing (main)

import Client.App.Models as App
import Client.App.App as App
import Html exposing (div)
import CssFrameworks
import CssFrameworks.Bootstrap
import Navigation


main : Program Never App.Model App.Msg
main =
    Navigation.program
        App.OnLocation
        { init = App.init
        , view = view
        , update = App.update
        , subscriptions = App.subscriptions
        }


view : App.Model -> Html.Html App.Msg
view model =
    div []
        [ App.view model
        , CssFrameworks.toStyleNode CssFrameworks.Bootstrap.bootstrap
        ]

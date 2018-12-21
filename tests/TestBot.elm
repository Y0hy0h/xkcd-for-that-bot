module TestBot exposing (suite)

import Bot exposing (bot)
import Elmegram.Bot as Elmegram
import Expect exposing (Expectation)
import Fuzz exposing (..)
import Telegram.Test as TeleTest
import Test exposing (..)


suite : Test
suite =
    let
        initModel =
            bot.init TeleTest.makeUser |> .model
    in
    describe "xkcd for that bot"
        [ test "/help sends help message" <|
            \_ ->
                let
                    message =
                        TeleTest.makeMessage "/help"

                    update =
                        TeleTest.send message
                in
                bot.update (bot.newUpdateMsg update) initModel
                    |> .methods
                    |> List.any
                        (\method ->
                            case method of
                                Elmegram.SendMessageMethod sendMessage ->
                                    sendMessage.text
                                        |> String.contains "relevant xkcd"

                                _ ->
                                    False
                        )
                    |> Expect.true "Expected a response containing a reference to 'relevant xkcd'."
        ]

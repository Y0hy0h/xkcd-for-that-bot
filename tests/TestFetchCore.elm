module TestFetchCore exposing (suite)

import Dict
import Expect exposing (Expectation)
import Fuzz exposing (..)
import Http
import Json.Decode as Decode
import Test exposing (..)
import Url exposing (Url)
import Xkcd
import Xkcd.FetchCore as Core


suite : Test
suite =
    describe "FetchCore"
        [ describe "fetchXkcd"
            [ test "url" <|
                \_ ->
                    Core.xkcdInfoUrl 349
                        |> Expect.equal (buildUrl "xkcd.com" "/349/info.0.json")
            , test "resolver" <|
                \_ ->
                    let
                        url =
                            buildUrl "xkcd.com" "/349/info.0.json"

                        json =
                            -- Actual reponse for the above url.
                            "{\"month\": \"11\", \"num\": 349, \"link\": \"\", \"year\": \"2007\", \"news\": \"\", \"safe_title\": \"Success\", \"transcript\": \"As a project wears on, standards for success slip lower and lower.\\n0 hours\\n[[Woman looking at man working on the computer.]]\\nMan: Okay, I should be able to dual-boot BSD soon.\\n6 hours\\n[[Man on the floor fiddling with the open tower in front of him.]]\\nMan: I'll be happy if I can get the system working like it was when I started.\\n10 hours\\n[[Man standing in front of the computer which now has a laptop plugged into the tower.]]\\nMan: Well the desktop's a lost cause, but I think I can fix the problems the laptop's developed.\\n24 hours\\n[[Man and woman swimming in the sea, island and beach seen in the distance.]]\\nMan: If we're lucky, the sharks will stay away until we reach shallow water.\\nWoman: If we make it back alive, you're never upgrading anything again.\\n{{ 40% of OpenBSD installs lead to shark attacks. It's their only standing security issue. }}\", \"alt\": \"40% of OpenBSD installs lead to shark attacks.  It's their only standing security issue.\", \"img\": \"https://imgs.xkcd.com/comics/success.png\", \"title\": \"Success\", \"day\": \"26\"}"

                        previewUrl =
                            buildUrl "imgs.xkcd.com" "/comics/success.png"
                    in
                    Core.fetchXkcdResolver 1 (buildGoodResponse url json)
                        |> Expect.equal
                            (Decode.decodeString Xkcd.decodeXkcd json
                                |> Result.mapError (\err -> "Test JSON appears to be invalid xkcd.\n" ++ Decode.errorToString err)
                            )
            ]
        ]


buildUrl : String -> String -> Url
buildUrl host path =
    { protocol = Url.Https
    , host = host
    , port_ = Nothing
    , path = path
    , query = Nothing
    , fragment = Nothing
    }


buildGoodResponse : Url -> String -> Http.Response String
buildGoodResponse url body =
    Http.GoodStatus_
        { url = Url.toString url
        , statusCode = 200
        , statusText = "OK"
        , headers = Dict.empty
        }
        body

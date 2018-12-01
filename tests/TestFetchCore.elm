module TestFetchCore exposing (suite)

import Dict
import Expect exposing (Expectation)
import Fuzz exposing (..)
import Http
import Json.Decode as Decode
import Random
import Test exposing (..)
import Url exposing (Url)
import Xkcd
import Xkcd.FetchCore as Core
import Xkcd.FetchError as Error


suite : Test
suite =
    describe "FetchCore"
        [ describe "fetchXkcd"
            [ test "url" <|
                \_ ->
                    Core.xkcdInfoUrl 349
                        |> Expect.equal (buildUrl "xkcd.com" "/349/info.0.json")
            , describe "resolver"
                [ test "valid response returns xkcd" <|
                    \_ ->
                        let
                            url =
                                buildUrl "xkcd.com" "/349/info.0.json"

                            json =
                                -- Actual reponse for the above url.
                                "{\"month\": \"11\", \"num\": 349, \"link\": \"\", \"year\": \"2007\", \"news\": \"\", \"safe_title\": \"Success\", \"transcript\": \"As a project wears on, standards for success slip lower and lower.\\n0 hours\\n[[Woman looking at man working on the computer.]]\\nMan: Okay, I should be able to dual-boot BSD soon.\\n6 hours\\n[[Man on the floor fiddling with the open tower in front of him.]]\\nMan: I'll be happy if I can get the system working like it was when I started.\\n10 hours\\n[[Man standing in front of the computer which now has a laptop plugged into the tower.]]\\nMan: Well the desktop's a lost cause, but I think I can fix the problems the laptop's developed.\\n24 hours\\n[[Man and woman swimming in the sea, island and beach seen in the distance.]]\\nMan: If we're lucky, the sharks will stay away until we reach shallow water.\\nWoman: If we make it back alive, you're never upgrading anything again.\\n{{ 40% of OpenBSD installs lead to shark attacks. It's their only standing security issue. }}\", \"alt\": \"40% of OpenBSD installs lead to shark attacks.  It's their only standing security issue.\", \"img\": \"https://imgs.xkcd.com/comics/success.png\", \"title\": \"Success\", \"day\": \"26\"}"

                            expectedXkcd =
                                Decode.decodeString Xkcd.decodeXkcd json
                                    |> Result.mapError (\_ -> Expect.fail "Test JSON was invalid.")
                        in
                        Core.fetchXkcdResolver 1 (buildGoodResponse url json)
                            |> Result.mapError (\_ -> Expect.fail "Expected resolver to succeed, but failed.")
                            |> expectEqualResults expectedXkcd
                , test "on 404 returns Unreleased error" <|
                    \_ ->
                        let
                            url =
                                buildUrl "xkcd.com" "/1000000/info.0.json"

                            badResponse =
                                Http.BadStatus_
                                    { url = Url.toString url
                                    , statusCode = 404
                                    , statusText = "NOT FOUND"
                                    , headers = Dict.empty
                                    }
                                    "xkcd not found."
                        in
                        Core.fetchXkcdResolver 1000000 badResponse
                            |> Expect.equal (Err <| Error.Unreleased 1000000)
                ]
            ]
        , describe "fetchCurrentXkcd"
            [ test "valid response returns xkcd" <|
                \_ ->
                    let
                        url =
                            buildUrl "xkcd.com" "/info.0.json"

                        json =
                            -- Actual reponse for xkcd #2079.
                            "{\"month\": \"11\", \"num\": 2079, \"link\": \"\", \"year\": \"2018\", \"news\": \"\", \"safe_title\": \"Alpha Centauri\", \"transcript\": \"\", \"alt\": \"And let's be honest, it's more like two and a half stars. Proxima is barely a star and barely bound to the system.\", \"img\": \"https://imgs.xkcd.com/comics/alpha_centauri.png\", \"title\": \"Alpha Centauri\", \"day\": \"30\"}"

                        expectedXkcd =
                            Decode.decodeString Xkcd.decodeXkcd json
                                |> Result.mapError (\_ -> Expect.fail "Test JSON was invalid.")
                    in
                    Core.fetchCurrentXkcdResolver (buildGoodResponse url json)
                        |> Result.mapError (\_ -> Expect.fail "Expected resolver to succeed, but failed.")
                        |> expectEqualResults expectedXkcd
            ]
        , let
            nonNegative =
                intRange 0 100

            xkcdId =
                intRange 1 1000000
          in
          describe "latestXkcdsFromCurrentId"
            [ fuzz3 nonNegative nonNegative xkcdId "result length equals amount" <|
                \amount offset id ->
                    let
                        possibleAmount =
                            min amount id
                    in
                    Core.latestXkcdIdsFromCurrentId { amount = amount, offset = offset } id
                        |> List.length
                        |> Expect.equal possibleAmount
            , fuzz3 nonNegative nonNegative xkcdId "result is sorted in descending order" <|
                \amount offset id ->
                    let
                        result =
                            Core.latestXkcdIdsFromCurrentId { amount = amount, offset = offset } id

                        descending a b =
                            case compare a b of
                                LT ->
                                    GT

                                EQ ->
                                    EQ

                                GT ->
                                    LT

                        sorted =
                            List.sortWith descending result
                    in
                    Expect.equal result sorted
            ]
        ]


expectEqualResults : Result Expectation a -> Result Expectation a -> Expectation
expectEqualResults first second =
    case Result.map2 Expect.equal first second of
        Ok pass ->
            pass

        Err fail ->
            fail



-- HTTP ERRORS


type FetchError invalid
    = Network HttpError
    | Invalid invalid
    | Unreleased Xkcd.XkcdId


type alias FetchXkcdError =
    FetchError Decode.Error


type alias FetchRelevantXkcdError =
    FetchError String


type HttpError
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata String


resultFromResponse : Http.Response String -> Result HttpError ( Http.Metadata, String )
resultFromResponse response =
    case response of
        Http.GoodStatus_ meta body ->
            Ok ( meta, body )

        Http.BadStatus_ meta body ->
            Err (BadStatus meta body)

        Http.BadUrl_ url ->
            Err (BadUrl url)

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError


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

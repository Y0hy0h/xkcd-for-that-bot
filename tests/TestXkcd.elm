module TestXkcd exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (..)
import Json.Decode as Decode
import Test exposing (..)
import Url exposing (Url)
import Xkcd exposing (Xkcd)


suite : Test
suite =
    describe "Xkcd"
        [ test "decodeXkcd" <|
            \_ ->
                let
                    xkcdJson =
                        """
                        {
                            "month": "11",
                            "num": 2070,
                            "link": "",
                            "year": "2018",
                            "news": "",
                            "safe_title": "Trig Identities",
                            "transcript": "",
                            "alt": "ARCTANGENT THETA = ENCHANT AT TARGET",
                            "img": "https://imgs.xkcd.com/comics/trig_identities.png",
                            "title": "Trig Identities",
                            "day": "9"
                        }
                        """

                    previewUrl =
                        buildUrl "imgs.xkcd.com" "/comics/trig_identities.png"

                    comicUrl =
                        buildUrl "xkcd.com" "/2070"

                    explainUrl =
                        buildUrl "www.explainxkcd.com" "/wiki/index.php/2070"
                in
                Decode.decodeString Xkcd.decodeXkcd xkcdJson
                    |> (\result ->
                            case result of
                                Ok xkcd ->
                                    Expect.all
                                        [ Xkcd.getId >> Expect.equal 2070
                                        , Xkcd.getPreviewUrl >> Expect.equal previewUrl
                                        , Xkcd.getTitle >> Expect.equal "Trig Identities"
                                        , Xkcd.getMouseOver >> Expect.equal "ARCTANGENT THETA = ENCHANT AT TARGET"
                                        , Xkcd.getTranscript >> Expect.equal Nothing
                                        , Xkcd.getComicUrl >> Expect.equal comicUrl
                                        , Xkcd.getExplainUrl >> Expect.equal explainUrl
                                        ]
                                        xkcd

                                Err err ->
                                    Expect.fail (Decode.errorToString err)
                       )
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

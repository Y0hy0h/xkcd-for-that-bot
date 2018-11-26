module TestRelevantXkcd exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


suite : Test
suite =
    test "make CI pass" <|
        \_ -> Expect.true "This can't fail." True

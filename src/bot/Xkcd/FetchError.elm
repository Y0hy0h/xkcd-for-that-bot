module Xkcd.FetchError exposing (FetchError(..), FetchRelevantXkcdError, FetchXkcdError, HttpError(..), stringFromFetchError, stringFromFetchRelevantXkcdError, stringFromFetchXkcdError)

import Http
import Json.Decode as Decode
import Xkcd


stringFromFetchRelevantXkcdError : FetchRelevantXkcdError -> String
stringFromFetchRelevantXkcdError error =
    stringFromFetchError identity error


type FetchError invalid
    = Network HttpError
    | Invalid invalid
    | Unreleased Xkcd.XkcdId


type alias FetchXkcdError =
    FetchError Decode.Error


stringFromFetchXkcdError : FetchXkcdError -> String
stringFromFetchXkcdError error =
    stringFromFetchError Decode.errorToString error


type alias FetchRelevantXkcdError =
    FetchError String


stringFromFetchError : (invalid -> String) -> FetchError invalid -> String
stringFromFetchError stringFromInvalid error =
    case error of
        Network httpError ->
            "Error while fetching xkcd."

        Invalid invalid ->
            stringFromInvalid invalid

        Unreleased id ->
            "xkcd #" ++ String.fromInt id ++ " is not yet released."


type HttpError
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata String

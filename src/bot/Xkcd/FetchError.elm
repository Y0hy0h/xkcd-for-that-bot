module Xkcd.FetchError exposing
    ( FetchXkcdError, FetchRelevantXkcdError, FetchError(..)
    , stringFromFetchXkcdError, stringFromFetchRelevantXkcdError, stringFromFetchError
    , HttpError(..), resultFromResponse
    )

{-| Possible errors when fetching xkcds.


## Errors

@docs FetchXkcdError, FetchRelevantXkcdError, FetchError


## Conversions

Convert the errors into human-readable string.

@docs stringFromFetchXkcdError, stringFromFetchRelevantXkcdError, stringFromFetchError


## HTTP Errors

@docs HttpError, resultFromResponse

-}

import Http
import Json.Decode as Decode
import Xkcd


{-| All possible failure cases when fetching xkcds.

The content for the Invalid case depends on the format of the response.
Responses containing JSON will want to return `Json.Decode.Error`, while custom
formatted responses will need a custom error type.

-}
type FetchError body invalid
    = Network (HttpError body)
    | Invalid invalid
    | Unreleased Xkcd.XkcdId


stringFromFetchError : (invalid -> String) -> FetchError body invalid -> String
stringFromFetchError stringFromInvalid error =
    case error of
        Network httpError ->
            "Error while fetching xkcd."

        Invalid invalid ->
            stringFromInvalid invalid

        Unreleased id ->
            "xkcd #" ++ String.fromInt id ++ " is not yet released."


{-| Shorthand for an error in a `String` response containing JSON.
-}
type alias FetchXkcdError =
    FetchError String Decode.Error


stringFromFetchXkcdError : FetchXkcdError -> String
stringFromFetchXkcdError error =
    stringFromFetchError Decode.errorToString error


{-| Shorthand for an error in a `String` response containing a custom format.
-}
type alias FetchRelevantXkcdError =
    FetchError String String


stringFromFetchRelevantXkcdError : FetchRelevantXkcdError -> String
stringFromFetchRelevantXkcdError error =
    stringFromFetchError identity error


{-| The [Http](https://package.elm-lang.org/packages/elm/http/latest) package
does not expose a type that only contains the error states. This custom error
type contains only the cases that have gone wrong.
-}
type HttpError body
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata body


{-| Convert a `Response` into a `Result`, e. g. for a
[`Resolver`](https://package.elm-lang.org/packages/elm/http/latest/Http#Resolver).

If everything goes well, the `Result` will contain the response's
`Http.Metadata` and body. In case of a failure, the `Err` will contain our
custom `HttpError`.

Using the `Result` package's functions, you can change and work with the
response and the error:

    intResolver : Http.Resolver String Int
    intResolver =
        Http.stringResolver
            (resultFromResponse
                >> Result.mapError
                    (\err ->
                        case err of
                            (BadStatus meta body) as original ->
                                if meta.statusCode == 404 then
                                    "Could not find the website."

                                else
                                    "Something went wrong."

                            _ ->
                                "Something went wrong."
                    )
                >> Result.andThen
                    (\{ body } ->
                        case String.toInt body of
                            Just int ->
                                Ok int

                            Nothing ->
                                Err "Response was not a valid integer."
                    )
            )

-}
resultFromResponse : Http.Response a -> Result (HttpError a) { meta : Http.Metadata, body : a }
resultFromResponse response =
    case response of
        Http.GoodStatus_ meta body ->
            Ok { meta = meta, body = body }

        Http.BadStatus_ meta body ->
            Err (BadStatus meta body)

        Http.BadUrl_ url ->
            Err (BadUrl url)

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError

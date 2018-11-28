module Xkcd.Fetch exposing
    ( fetchXkcd, fetchXkcds, fetchCurrentXkcd, fetchLatestXkcdIds, fetchRelevantIds
    , currentXkcdInfoUrl, parseResponse, parseXkcd, parseXkcdId, queryUrl, xkcdInfoUrl
    )

{-| Fetch xkcds by id, chronologically or by relevance.


## Fetching Xkcds

@docs fetchXkcd, fetchXkcds, fetchCurrentXkcd, fetchLatestXkcdIds, fetchRelevantIds

-}

import Http
import Json.Decode as Decode
import Task exposing (Task)
import Url exposing (Url)
import Xkcd exposing (..)


{-| Fetch the xkcd corresponding to the id over HTTP.
-}
fetchXkcd : XkcdId -> Task String Xkcd
fetchXkcd id =
    Http.task
        { method = "GET"
        , headers = []
        , url = Url.toString (xkcdInfoUrl id)
        , body = Http.emptyBody
        , resolver =
            Http.stringResolver
                (\response ->
                    let
                        genericError =
                            Err ("Error fetching xkcd with id " ++ String.fromInt id ++ ".")
                    in
                    case response of
                        Http.GoodStatus_ _ res ->
                            parseXkcd res

                        Http.BadStatus_ { statusCode } _ ->
                            if statusCode == 404 then
                                Err ("#" ++ String.fromInt id ++ " is not yet released.")

                            else
                                genericError

                        _ ->
                            genericError
                )
        , timeout = Nothing
        }


xkcdInfoUrl : XkcdId -> Url
xkcdInfoUrl id =
    { protocol = Url.Https
    , host = "xkcd.com"
    , port_ = Nothing
    , path = "/" ++ String.fromInt id ++ "/info.0.json"
    , query = Nothing
    , fragment = Nothing
    }


{-| Convenience function that fetches all corresponding xkcds over HTTP.
-}
fetchXkcds : List XkcdId -> Task String (List Xkcd)
fetchXkcds ids =
    Task.sequence (List.map fetchXkcd ids)


fetchCurrentXkcd : Task String Xkcd
fetchCurrentXkcd =
    Http.task
        { method = "GET"
        , headers = []
        , url = Url.toString currentXkcdInfoUrl
        , body = Http.emptyBody
        , resolver =
            Http.stringResolver
                (\response ->
                    case response of
                        Http.GoodStatus_ _ res ->
                            parseXkcd res

                        _ ->
                            Err "Error fetching current xkcd."
                )
        , timeout = Nothing
        }


currentXkcdInfoUrl : Url
currentXkcdInfoUrl =
    { protocol = Url.Https
    , host = "xkcd.com"
    , port_ = Nothing
    , path = "/info.0.json"
    , query = Nothing
    , fragment = Nothing
    }


{-| Fetches a list of the latest xkds over HTTP.

The resulting list has at most `amount` many entries, and is ordered by decreasing ids (latest to oldest).
The latest xkcd in the list will be `offset` older than the current xkcd.

`amount` and `offset` are supposed to be non-negative. Negative inputs will be normalized to 0.

-}
fetchLatestXkcdIds : { amount : Int, offset : Int } -> Task String (List XkcdId)
fetchLatestXkcdIds { amount, offset } =
    fetchCurrentXkcd
        |> Task.map
            (\currentXkcd ->
                let
                    sanitizedOffset =
                        max 0 offset

                    sanitizedAmount =
                        max 0 amount

                    latestId =
                        getId currentXkcd

                    maxId =
                        latestId - sanitizedOffset

                    minId =
                        max 0 (maxId - sanitizedAmount)
                in
                List.range minId maxId
                    |> List.reverse
            )


{-| Fetches the most relevant xkds' ids for the query over HTTP.

Relevance is according to <https://relevantxkcd.appspot.com/>.

-}
fetchRelevantIds : String -> Task String (List XkcdId)
fetchRelevantIds query =
    Http.task
        { method = "GET"
        , headers = []
        , url = Url.toString (queryUrl query)
        , body = Http.emptyBody
        , resolver =
            Http.stringResolver
                (\response ->
                    case response of
                        Http.GoodStatus_ _ body ->
                            parseResponse body

                        _ ->
                            Err "Error fetching xkcd."
                )
        , timeout = Nothing
        }


queryUrl : String -> Url
queryUrl query =
    { protocol = Url.Https
    , host = "relevantxkcd.appspot.com"
    , port_ = Nothing
    , path = "/process"
    , query = Just ("action=xkcd&query=" ++ query)
    , fragment = Nothing
    }


parseResponse : String -> Result String (List XkcdId)
parseResponse body =
    let
        dropFromEnd amount list =
            List.take (List.length list - amount) list

        sanitizeBody =
            -- The first two entries are statistics.
            List.drop 2
                -- The last line is a newline.
                >> dropFromEnd 1
    in
    String.lines body
        |> sanitizeBody
        |> List.map parseXkcdId
        |> List.foldl
            (\result list ->
                Result.map2 (\xkcd existing -> existing ++ [ xkcd ]) result list
            )
            (Ok [])


parseXkcdId : String -> Result String XkcdId
parseXkcdId line =
    case String.words line of
        idString :: urlString :: [] ->
            case String.toInt idString of
                Just id ->
                    Ok id

                _ ->
                    Err "Malformed line. Could not convert id."

        malformed ->
            Err <| "Malformed line. Expected 2 fields, got " ++ (List.length malformed |> String.fromInt) ++ "."


parseXkcd : String -> Result String Xkcd
parseXkcd raw =
    Decode.decodeString
        decodeXkcd
        raw
        |> Result.mapError Decode.errorToString

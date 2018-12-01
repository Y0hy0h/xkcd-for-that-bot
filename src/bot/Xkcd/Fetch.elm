module Xkcd.Fetch exposing
    ( fetchXkcd, fetchXkcds, fetchCurrentXkcd, fetchLatestXkcdIds, fetchRelevantIds
    , FetchError, FetchRelevantXkcdError, FetchXkcdError, stringFromFetchError, stringFromFetchRelevantXkcdError, stringFromFetchXkcdError
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
import Xkcd.FetchCore as Core


{-| Fetch the xkcd corresponding to the id over HTTP.
-}
fetchXkcd : XkcdId -> Task FetchXkcdError Xkcd
fetchXkcd id =
    Http.task
        { method = "GET"
        , headers = []
        , url = Url.toString (Core.xkcdInfoUrl id)
        , body = Http.emptyBody
        , resolver = Http.stringResolver (Core.fetchXkcdResolver id)
        , timeout = Nothing
        }


{-| Convenience function that fetches all corresponding xkcds over HTTP.
-}
fetchXkcds : List XkcdId -> Task FetchXkcdError (List Xkcd)
fetchXkcds ids =
    Task.sequence (List.map fetchXkcd ids)


{-| Fetch the latest xkcd over HTTP.
-}
fetchCurrentXkcd : Task FetchXkcdError Xkcd
fetchCurrentXkcd =
    Http.task
        { method = "GET"
        , headers = []
        , url = Url.toString Core.currentXkcdInfoUrl
        , body = Http.emptyBody
        , resolver = Http.stringResolver Core.fetchCurrentXkcdResolver
        , timeout = Nothing
        }


{-| Fetches a list of the latest xkds over HTTP.

The resulting list has at most `amount` many entries, and is ordered by decreasing ids (latest to oldest).
The latest xkcd in the list will be `offset` older than the current xkcd.

`amount` and `offset` are supposed to be non-negative. Negative inputs will be normalized to 0.

-}
fetchLatestXkcdIds : { amount : Int, offset : Int } -> Task FetchXkcdError (List XkcdId)
fetchLatestXkcdIds config =
    fetchCurrentXkcd
        |> Task.map (Xkcd.getId >> Core.latestXkcdIdsFromCurrentId config)


{-| Fetches the most relevant xkds' ids for the query over HTTP.

Relevance is according to <https://relevantxkcd.appspot.com/>.

-}
fetchRelevantIds : String -> Task FetchRelevantXkcdError (List XkcdId)
fetchRelevantIds query =
    Http.task
        { method = "GET"
        , headers = []
        , url = Url.toString (Core.relevantXkcdUrl query)
        , body = Http.emptyBody
        , resolver = Http.stringResolver Core.fetchRelevantIdsResolver
        , timeout = Nothing
        }



-- ERRORS


type alias FetchError invalid =
    Core.FetchError invalid


stringFromFetchError : (invalid -> String) -> FetchError invalid -> String
stringFromFetchError stringFromInvalid error =
    case error of
        Core.Network httpError ->
            "Error while fetching xkcd."

        Core.Invalid invalid ->
            stringFromInvalid invalid

        Core.Unreleased id ->
            "xkcd #" ++ String.fromInt id ++ " is not yet released."


type alias FetchXkcdError =
    Core.FetchXkcdError


stringFromFetchXkcdError : FetchXkcdError -> String
stringFromFetchXkcdError error =
    stringFromFetchError Decode.errorToString error


type alias FetchRelevantXkcdError =
    Core.FetchRelevantXkcdError


stringFromFetchRelevantXkcdError : FetchRelevantXkcdError -> String
stringFromFetchRelevantXkcdError error =
    stringFromFetchError identity error

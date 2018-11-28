module Xkcd.FetchCore exposing (currentXkcdInfoUrl, fetchCurrentXkcdResolver, fetchRelevantIdsResolver, fetchXkcdResolver, latestXkcdIdsFromCurrentId, relevantXkcdUrl, xkcdInfoUrl)

{-| Core functionality for Fetch. Meant for import by tests only.
-}

import Http
import Json.Decode as Decode
import Task exposing (Task)
import Url exposing (Url)
import Xkcd exposing (..)


xkcdInfoUrl : XkcdId -> Url
xkcdInfoUrl id =
    { protocol = Url.Https
    , host = "xkcd.com"
    , port_ = Nothing
    , path = "/" ++ String.fromInt id ++ "/info.0.json"
    , query = Nothing
    , fragment = Nothing
    }


fetchXkcdResolver : Int -> Http.Response String -> Result String Xkcd
fetchXkcdResolver id response =
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


currentXkcdInfoUrl : Url
currentXkcdInfoUrl =
    { protocol = Url.Https
    , host = "xkcd.com"
    , port_ = Nothing
    , path = "/info.0.json"
    , query = Nothing
    , fragment = Nothing
    }


fetchCurrentXkcdResolver : Http.Response String -> Result String Xkcd
fetchCurrentXkcdResolver response =
    case response of
        Http.GoodStatus_ _ res ->
            parseXkcd res

        _ ->
            Err "Error fetching current xkcd."


latestXkcdIdsFromCurrentId : { amount : Int, offset : Int } -> XkcdId -> List XkcdId
latestXkcdIdsFromCurrentId { amount, offset } currentId =
    let
        sanitizedOffset =
            max 0 offset

        sanitizedAmount =
            max 0 amount

        maxId =
            currentId - sanitizedOffset

        minId =
            max 0 (maxId - sanitizedAmount)
    in
    List.range minId maxId
        |> List.reverse


relevantXkcdUrl : String -> Url
relevantXkcdUrl query =
    { protocol = Url.Https
    , host = "relevantxkcd.appspot.com"
    , port_ = Nothing
    , path = "/process"
    , query = Just ("action=xkcd&query=" ++ query)
    , fragment = Nothing
    }


fetchRelevantIdsResolver : Http.Response String -> Result String (List XkcdId)
fetchRelevantIdsResolver response =
    case response of
        Http.GoodStatus_ _ body ->
            parseResponse body

        _ ->
            Err "Error fetching xkcd."


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

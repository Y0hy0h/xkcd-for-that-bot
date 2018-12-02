module Xkcd exposing (Xkcd, XkcdId, getId, getPreviewUrl, getTitle, getMouseOver, getTranscript, getComicUrl, getExplainUrl, decodeXkcd)

{-| Fetch xkcds by id or relevance to a query.


## Xkcd

@docs Xkcd, XkcdId, getId, getPreviewUrl, getTitle, getMouseOver, getTranscript, getComicUrl, getExplainUrl, decodeXkcd

-}

import Http
import Json.Decode as Decode
import Task exposing (Task)
import Url exposing (Url)
import Url.Builder



-- XKCD


{-| Container for all information about an xkcd.
-}
type Xkcd
    = Xkcd XkcdContent


type alias XkcdContent =
    { id : XkcdId
    , previewUrl : Url
    , title : String
    , mouseOver : String
    , transcript : Maybe String
    }


{-| An Xkcd's id.
-}
type alias XkcdId =
    Int


{-| The official id.
-}
getId : Xkcd -> Int
getId (Xkcd xkcd) =
    xkcd.id


{-| The url of the image preview for the xkcd.
-}
getPreviewUrl : Xkcd -> Url
getPreviewUrl (Xkcd xkcd) =
    xkcd.previewUrl


{-| The xkcd's title.

The unsafe version.

-}
getTitle : Xkcd -> String
getTitle (Xkcd xkcd) =
    xkcd.title


{-| The alt text that appears when hovering with the mouse over the xkcd.
-}
getMouseOver : Xkcd -> String
getMouseOver (Xkcd xkcd) =
    xkcd.mouseOver


{-| The official transcript of the xkcd.

Because of an issue on xkcd.com, the transcript might be missing on newer xkcds.
See the [explanation on ExplainXKCD](https://www.explainxkcd.com/wiki/index.php/Transcript_on_xkcd)
for further information.

In light of these issues, this library does not offer transcripts for xkcds with
an id greater than 1608.

-}
getTranscript : Xkcd -> Maybe String
getTranscript (Xkcd xkcd) =
    xkcd.transcript


{-| The url to the official site for the comic.
-}
getComicUrl : Xkcd -> Url
getComicUrl (Xkcd xkcd) =
    { protocol = Url.Https
    , host = "xkcd.com"
    , port_ = Nothing
    , path = "/" ++ String.fromInt xkcd.id
    , query = Nothing
    , fragment = Nothing
    }


{-| The url to the explanation for the comic.
-}
getExplainUrl : Xkcd -> Url
getExplainUrl (Xkcd xkcd) =
    { protocol = Url.Https
    , host = "www.explainxkcd.com"
    , port_ = Nothing
    , path = "/wiki/index.php/" ++ String.fromInt xkcd.id
    , query = Nothing
    , fragment = Nothing
    }


{-| Decodes the JSON returned by the official xkcd site.
-}
decodeXkcd : Decode.Decoder Xkcd
decodeXkcd =
    let
        decodeUrl =
            Decode.string
                |> Decode.andThen
                    (\urlString ->
                        case Url.fromString urlString of
                            Just url ->
                                Decode.succeed url

                            Nothing ->
                                Decode.fail ("Invalid url '" ++ urlString ++ "'.")
                    )

        -- Transcripts are broken for xkcds after #1608. See https://www.explainxkcd.com/wiki/index.php/Transcript_on_xkcd for details.
        sanitizeTranscript xkcdContent =
            { xkcdContent
                | transcript =
                    if xkcdContent.id > 1608 then
                        Nothing

                    else
                        xkcdContent.transcript
            }
    in
    Decode.map5
        XkcdContent
        (Decode.field "num" Decode.int)
        (Decode.field "img" decodeUrl)
        (Decode.field "title" Decode.string)
        (Decode.field "alt" Decode.string)
        (Decode.field "transcript" (Decode.string |> Decode.map Just))
        |> Decode.map sanitizeTranscript
        |> Decode.map Xkcd

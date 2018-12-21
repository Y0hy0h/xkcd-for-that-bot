port module Main exposing (bot)

import Dict exposing (Dict)
import Elmegram
import Elmegram.Bot as Bot
import Elmegram.Custom
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import String.Extra as String
import Task exposing (Task)
import Telegram
import Url
import Xkcd
import Xkcd.Fetch as Xkcd
import Xkcd.FetchError as XkcdError


bot =
    { init = init
    , newUpdateMsg = NewUpdate
    , update = update
    }


type alias Response =
    Bot.Response Model Msg


type alias Model =
    { self : Telegram.User
    , cacheSingles : Dict String Xkcd.Xkcd
    , cacheLists : Dict String (List Xkcd.Xkcd)
    }


init : Bot.Init Model Msg
init user =
    keep
        { self = user
        , cacheSingles = Dict.empty
        , cacheLists = Dict.empty
        }


type Msg
    = NewUpdate Telegram.Update
    | CacheFetchXkcd (Handler (Result String Xkcd.Xkcd)) String (Result String Xkcd.Xkcd)
    | CacheFetchXkcds (Handler (Result String (List Xkcd.Xkcd))) String (Result String (List Xkcd.Xkcd))


newUpdateMsg : Telegram.Update -> Msg
newUpdateMsg =
    NewUpdate


update : Bot.Update Model Msg
update msg model =
    let
        handleUpdate : Telegram.Update -> Response
        handleUpdate newUpdate =
            case newUpdate.content of
                Telegram.MessageUpdate message ->
                    -- Help Command
                    if Elmegram.matchesCommand "start" message || Elmegram.matchesCommand "help" message then
                        simply [ helpMessage model.self message.chat ] model
                        -- Invalid Command

                    else if Elmegram.containsCommand message then
                        simply [ commandNotFoundMessage model.self message ] model
                        -- xkcd Query

                    else
                        withSuitableXkcd
                            message.text
                            model
                            (\mdl result ->
                                case result of
                                    Ok xkcd ->
                                        simply [ answerWithXkcd message.chat xkcd ] mdl

                                    Err err ->
                                        simply [ Elmegram.makeAnswer message.chat err |> Bot.SendMessageMethod ] mdl
                            )

                Telegram.InlineQueryUpdate inlineQuery ->
                    let
                        offset =
                            String.toInt inlineQuery.offset |> Maybe.withDefault 0
                    in
                    withSuitableXkcds
                        inlineQuery.query
                        { amount = 10, offset = offset }
                        model
                        (\mdl result ->
                            case result of
                                Ok xkcds ->
                                    let
                                        newOffset =
                                            List.length xkcds |> String.fromInt
                                    in
                                    simply [ answerInlineQueryWithXkcds inlineQuery newOffset xkcds ] mdl

                                Err _ ->
                                    simply [ answerInlineQueryWithXkcds inlineQuery "" [] ] mdl
                        )

                Telegram.CallbackQueryUpdate callbackQuery ->
                    case String.toInt callbackQuery.data of
                        Just id ->
                            withSuitableXkcd
                                (String.fromInt id)
                                model
                                (\mdl result ->
                                    case result of
                                        Ok xkcd ->
                                            simply [ answerCallbackWithXkcd callbackQuery xkcd ] mdl

                                        Err _ ->
                                            simply [ answerCallbackFail callbackQuery ] mdl
                                )

                        Nothing ->
                            simply [ answerCallbackFail callbackQuery ] model
    in
    case msg of
        NewUpdate telegramUpdate ->
            handleUpdate telegramUpdate

        CacheFetchXkcd processResult query result ->
            case result of
                Ok xkcd ->
                    processResult { model | cacheSingles = Dict.insert query xkcd model.cacheSingles } (Ok xkcd)

                Err err ->
                    processResult model (Err err)

        CacheFetchXkcds processResult query result ->
            case result of
                Ok xkcds ->
                    processResult { model | cacheLists = Dict.insert query xkcds model.cacheLists } (Ok xkcds)

                Err err ->
                    processResult model (Err err)



-- xkcd Messages


answerWithXkcd : Telegram.Chat -> Xkcd.Xkcd -> Bot.Method
answerWithXkcd to xkcd =
    let
        incompleteAnswer =
            Elmegram.makeAnswerFormatted to (xkcdText xkcd)

        answer =
            { incompleteAnswer
                | reply_markup = Just <| Telegram.InlineKeyboardMarkup (xkcdKeyboard xkcd)
            }
    in
    Bot.SendMessageMethod answer


xkcdHeading : Xkcd.Xkcd -> String
xkcdHeading xkcd =
    ("#" ++ (String.fromInt <| Xkcd.getId xkcd) ++ ": ")
        ++ Xkcd.getTitle xkcd


xkcdText : Xkcd.Xkcd -> Elmegram.FormattedText
xkcdText xkcd =
    Elmegram.format Telegram.Html
        (("<b>" ++ xkcdHeading xkcd ++ "</b>\n")
            ++ (Url.toString <| Xkcd.getComicUrl xkcd)
        )


xkcdKeyboard : Xkcd.Xkcd -> Telegram.InlineKeyboard
xkcdKeyboard xkcd =
    [ [ Telegram.CallbackButton (Xkcd.getId xkcd |> String.fromInt) "Show mouse-over" ]
    , [ Telegram.UrlButton (Xkcd.getExplainUrl xkcd) "Explain xkcd" ]
    ]



-- Inline Queries


answerInlineQueryWithXkcds : Telegram.InlineQuery -> String -> List Xkcd.Xkcd -> Bot.Method
answerInlineQueryWithXkcds to newOffset xkcds =
    let
        results =
            List.map
                (\xkcd ->
                    let
                        article =
                            Elmegram.makeMinimalInlineQueryResultArticle
                                { id = String.fromInt <| Xkcd.getId xkcd
                                , title = xkcdHeading xkcd
                                , message = Elmegram.makeInputMessageFormatted <| xkcdText xkcd
                                }
                    in
                    { article
                        | description = Xkcd.getTranscript xkcd
                        , url = Just <| Telegram.Hide (Xkcd.getComicUrl xkcd)
                        , thumb_url = Just (Xkcd.getPreviewUrl xkcd)
                        , reply_markup = Just (xkcdKeyboard xkcd)
                    }
                        |> Elmegram.inlineQueryResultFromArticle
                )
                xkcds

        incompleteInlineQueryAnswer =
            Elmegram.makeAnswerInlineQuery to results

        rawInlineQueryAnswer =
            { incompleteInlineQueryAnswer
                | next_offset = Just newOffset
            }
    in
    rawInlineQueryAnswer |> Bot.AnswerInlineQueryMethod



-- Callbacks


answerCallbackWithXkcd : Telegram.CallbackQuery -> Xkcd.Xkcd -> Bot.Method
answerCallbackWithXkcd to xkcd =
    let
        incompleteAnswer =
            Elmegram.makeAnswerCallbackQuery to

        answer =
            { incompleteAnswer
                | text = Just <| (Xkcd.getMouseOver xkcd |> String.ellipsis 200)
                , show_alert = True
            }
    in
    answer |> Bot.AnswerCallbackQueryMethod


answerCallbackFail : Telegram.CallbackQuery -> Bot.Method
answerCallbackFail to =
    Elmegram.makeAnswerCallbackQuery to
        |> Bot.AnswerCallbackQueryMethod



-- Help Messages


helpMessage : Telegram.User -> Telegram.Chat -> Bot.Method
helpMessage self chat =
    Elmegram.makeAnswerFormatted
        chat
        (Elmegram.format
            Telegram.Markdown
            (helpText self)
        )
        |> Bot.SendMessageMethod


helpText : Telegram.User -> String
helpText self =
    "Type `@"
        ++ Elmegram.getDisplayName self
        ++ " <query>` in any chat to search for [relevant xkcd](https://relevantxkcd.appspot.com/) comics."
        ++ "To get the latest comics, just enter nothing as the query.\n"
        ++ "\n"
        ++ "You can also just send me messages here. I will answer with the xkcd most relevant to what you sent me."


commandNotFoundMessage : Telegram.User -> Telegram.TextMessage -> Bot.Method
commandNotFoundMessage self message =
    Elmegram.makeReplyFormatted
        message
        (Elmegram.format
            Telegram.Markdown
            ("I did not understand that command.\n\n" ++ helpText self)
        )
        |> Bot.SendMessageMethod



-- LOGIC


type alias Handler a =
    Model -> a -> Response


withSuitableXkcd : String -> Model -> Handler (Result String Xkcd.Xkcd) -> Response
withSuitableXkcd query model processResult =
    case Dict.get query model.cacheSingles of
        Just xkcd ->
            processResult model (Ok xkcd)

        Nothing ->
            let
                cmd =
                    fetchSuitableXkcd query
                        |> Task.attempt (CacheFetchXkcd processResult query)
            in
            do [] model cmd


fetchSuitableXkcd : String -> Task String Xkcd.Xkcd
fetchSuitableXkcd query =
    let
        fetchCurrent =
            Xkcd.fetchCurrentXkcd
    in
    if String.isEmpty query then
        fetchCurrent
            |> Task.mapError XkcdError.stringFromFetchXkcdError

    else
        case String.toInt query of
            Just id ->
                Xkcd.fetchXkcd id
                    |> Task.mapError XkcdError.stringFromFetchXkcdError

            Nothing ->
                Xkcd.fetchRelevantXkcdIds query
                    |> Task.mapError XkcdError.stringFromFetchRelevantXkcdError
                    |> Task.andThen
                        (\ids ->
                            case ids of
                                bestMatch :: _ ->
                                    Xkcd.fetchXkcd bestMatch
                                        |> Task.mapError XkcdError.stringFromFetchXkcdError

                                _ ->
                                    Task.fail ("No relevant xkcd for query '" ++ query ++ "'.")
                        )


withSuitableXkcds : String -> { amount : Int, offset : Int } -> Model -> Handler (Result String (List Xkcd.Xkcd)) -> Response
withSuitableXkcds query config model processResult =
    case Dict.get query model.cacheLists of
        Just xkcd ->
            processResult model (Ok xkcd)

        Nothing ->
            let
                cmd =
                    fetchSuitableXkcds query config
                        |> Task.attempt (CacheFetchXkcds processResult query)
            in
            do [] model cmd


fetchSuitableXkcds : String -> { amount : Int, offset : Int } -> Task String (List Xkcd.Xkcd)
fetchSuitableXkcds query { amount, offset } =
    let
        fetchLatest =
            Xkcd.fetchLatestXkcdIds { amount = max 0 amount, offset = offset }
                |> Task.andThen Xkcd.fetchXkcds
    in
    if String.isEmpty query then
        fetchLatest
            |> Task.mapError XkcdError.stringFromFetchXkcdError

    else
        case String.toInt query of
            Just id ->
                Xkcd.fetchXkcd id
                    |> Task.mapError XkcdError.stringFromFetchXkcdError
                    |> Task.andThen
                        (\exactMatch ->
                            fetchRelevantXkcds (max 0 (amount - 1)) query
                                |> Task.map
                                    (\xkcds ->
                                        let
                                            cleanedXkcds =
                                                List.filter (\xkcd -> xkcd /= exactMatch) xkcds
                                        in
                                        exactMatch :: cleanedXkcds
                                    )
                        )
                    |> Task.onError
                        (\_ -> fetchRelevantXkcds (max 0 amount) query)

            Nothing ->
                fetchRelevantXkcds amount query


fetchRelevantXkcds : Int -> String -> Task String (List Xkcd.Xkcd)
fetchRelevantXkcds amount query =
    Xkcd.fetchRelevantXkcdIds query
        |> Task.mapError XkcdError.stringFromFetchRelevantXkcdError
        |> Task.andThen
            (Xkcd.fetchXkcds
                >> Task.mapError XkcdError.stringFromFetchXkcdError
            )
        |> Task.map (List.take amount)



-- HELPERS


do : List Bot.Method -> Model -> Cmd Msg -> Response
do methods model cmd =
    { methods = methods
    , model = model
    , cmd = cmd
    }


simply : List Bot.Method -> Model -> Response
simply methods model =
    { methods = methods
    , model = model
    , cmd = Cmd.none
    }


keep : Model -> Response
keep model =
    { methods = []
    , model = model
    , cmd = Cmd.none
    }

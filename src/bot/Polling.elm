module Polling exposing (main)

import Bot


main =
    Elmegram.Custom.botRunner
        Bot.bot
        { incomingUpdate = incomingUpdatePort
        , sendMethod = methodPort
        , console = consolePort
        }



-- PORTS


port consolePort : Elmegram.Custom.ConsolePort msg


port methodPort : Elmegram.Custom.SendMethodPort msg


port incomingUpdatePort : Elmegram.Custom.IncomingUpdatePort msg

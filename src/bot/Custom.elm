port module Custom exposing (main)

import Bot
import Elmegram.Custom


main =
    Elmegram.Custom.botRunner
        Bot.bot
        { console = consolePort
        , sendMethod = sendMethodPort
        , incomingUpdate = incomingUpdatePort
        }



-- PORTS


port consolePort : Elmegram.Custom.ConsolePort msg


port sendMethodPort : Elmegram.Custom.SendMethodPort msg


port incomingUpdatePort : Elmegram.Custom.IncomingUpdatePort msg

port module Polling exposing (main)

import Bot
import Elmegram.Polling


main =
    Elmegram.Polling.botRunner
        Bot.bot
        consolePort



-- PORTS


port consolePort : Elmegram.Polling.ConsolePort msg

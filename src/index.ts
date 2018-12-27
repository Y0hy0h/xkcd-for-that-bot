import Express from 'express';
import bodyParser from 'body-parser';
import * as Path from 'path';
import * as Elmegram from 'elmegram.js';

startBot(Express())

async function startBot(app: Express.Express) {
  const unverifiedToken = getToken();

  if (process.env.NODE_ENV && process.env.NODE_ENV == 'dev') {
    console.log('Development mode, starting to poll.')
    Elmegram.startPolling(unverifiedToken, Path.resolve(__dirname, "../src/bot/Polling.elm"));
  } else {
    console.log('Starting bot in production mode.')

    app.use(bodyParser.json());

    const compiled = await Elmegram.BotCompiler.compile(
      Elmegram.CustomBot,
      Path.resolve(__dirname, "../src/bot/Custom.elm"),
      false
    );
    const bot = compiled.start(unverifiedToken);
    bot.onConsole(function (log: { level: string, message: string }) {
      console[log.level](log.message);
    });
    bot.onSendMessage(toSend => {
      console.log(toSend)
    })

    setupWebhook(unverifiedToken, bot, app);

    const listener = app.listen(process.env.PORT, function () {
      let address = listener.address();
      if (typeof address != 'string') {
        address = address.address + ":" + address.port;
      }
      console.log('Your app is listening at ' + address)
    })
  }
}

export function getToken(): string {
  const tokenName = 'TELEGRAM_TOKEN';
  const unverifiedToken = process.env[tokenName];
  if (typeof unverifiedToken == 'undefined') {
    console.error(`The environment variable ${tokenName} is not set. Please provide the Telegram token using it.`);
    throw new Error('Telegram token env var not set.')
  }
  return unverifiedToken;
}

async function setupWebhook(token: string, bot, app: Express.Router) {
  const hookUrl = getWebhookUrl(token);
  const webhookUrl = hookUrl.fullUrl;
  console.log(`Starting to listen for webhooks at ${hookUrl.censoredUrl}.`)

  app.use(`/bot/${token}`, async (req, res, next) => {
    console.log("\nReceived update:");
    console.log(req.body);
    bot.sendUpdates(req.body.result);
    res.sendStatus(200);
  });
}

function getWebhookUrl(token: string): { fullUrl: string, censoredUrl: string } {
  const domain = process.env.HOST_DOMAIN || "localhost";
  const baseUrl = `${domain}/bot/`;
  return { fullUrl: baseUrl + token, censoredUrl: `${baseUrl}<token>` };
}
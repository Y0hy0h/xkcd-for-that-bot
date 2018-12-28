import Express from 'express';
import bodyParser from 'body-parser';
import * as Path from 'path';
import * as Elmegram from 'elmegram.js';
import Axios from 'axios';

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
      Axios.post(
        getMethodUrl(unverifiedToken, toSend.methodName),
        toSend.content,
      ).then(() => {
        console.log(`Successfully sent method ${toSend.methodName} containing:`);
        console.log(JSON.stringify(toSend.content, undefined, 2));
      }).catch(error => {
        console.error(`Error when trying to send method ${toSend.methodName} containing:`);
        console.error(JSON.stringify(toSend.content, undefined, 2));
        console.error(error.toString());
        if (error.response) {
          console.error('Response contained:');
          console.error(error.response.data);
        }
      });
    });

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
    bot.sendUpdates([req.body]);
    res.sendStatus(200);
  });
}

function getWebhookUrl(token: string): { fullUrl: string, censoredUrl: string } {
  const rootUrl = getRootUrl();
  return { fullUrl: `${rootUrl}/token`, censoredUrl: `${rootUrl}/<token>` };
}

function getRootUrl(): string {
  const domain = process.env.HOST_DOMAIN || "localhost";
  return `${domain}/bot`;
}

function getMethodUrl(token: string, method: string): string {
  return `https://api.telegram.org/bot${token}/${method}`;
}
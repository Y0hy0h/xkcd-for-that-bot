import Express from 'express';
import path from 'path';
import bodyParser from 'body-parser';
import { setupBot, startPolling, setupWebhook } from '../packages/elmegram.js';
const Bot = require('./bot.js');

startServer(Express())

async function startServer(app: Express.Express) {
  app.use(bodyParser.json());

  // Static website
  app.use(Express.static(path.join(__dirname, '/public/')))

  const unverifiedToken = getToken();
  if (process.env.NODE_ENV && process.env.NODE_ENV == 'dev') {
    console.log('Development mode, starting to poll.')
    startPolling(unverifiedToken, Bot);
  } else {
    const { token, handleUpdate } = await setupBot(unverifiedToken, Bot);
    const hookUrl = getWebhookUrl(token);
    const webhookUrl = hookUrl.fullUrl;
    console.log(`Starting to listen for webhooks at ${hookUrl.censoredUrl}.`)
    await setupWebhook(token, webhookUrl);
    app.use(`/bot/${token}`, async (req, res, next) => {
      console.log("\nReceived update:");
      console.log(req.body);
      handleUpdate(req.body);
      res.sendStatus(200);
    });
  }

  const listener = app.listen(process.env.PORT, function () {
    let address = listener.address();
    if (typeof address != 'string') {
      address = address.address + ":" + address.port;
    }
    console.log('Your app is listening at ' + address)
  })
}

function getWebhookUrl(token: string): { fullUrl: string, censoredUrl: string } {
  const domain = process.env.HOST_DOMAIN || "localhost";
  const baseUrl = `${domain}/bot/`;
  return { fullUrl: baseUrl + token, censoredUrl: `${baseUrl}<token>` };
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
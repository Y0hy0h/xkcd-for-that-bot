import * as Express from 'express';
import * as path from 'path';
import * as bodyParser from 'body-parser';
import { setupBot, startPolling, setupWebhook } from './elmegram.js';
const Bot = require('./bot.js')

startServer(Express())

async function startServer(app: Express) {
  app.use(bodyParser.json());

  // Static website
  app.use(Express.static(path.join(__dirname, '/public/')))

  const unverifiedToken = getToken();
  console.log(process.env.NODE_ENV)
  if (process.env.NODE_ENV && process.env.NODE_ENV == 'dev') {
    console.log('Development mode, starting to poll.')
    startPolling(unverifiedToken, Bot);
  } else {
    console.log('Starting to listen to webhooks.')
    const { token, handleUpdate } = await setupBot(unverifiedToken, Bot);
    const webhookUrl = getWebhookUrl(token);
    await setupWebhook(token, webhookUrl);
    app.use(`/bot/${token}`, async (req, res, next) => {
      console.log("\nReceived update:");
      console.log(req.body);
      handleUpdate(req.body);
      res.sendStatus(200);
    });
  }

  const listener = app.listen(process.env.PORT, function () {
    console.log('Your app is listening on port ' + listener.address().port)
  })
}

function getWebhookUrl(token: string): string {
  const domain = process.env.PROJECT_DOMAIN
  const host = `${domain}.glitch.me`
  return `${host}/bot/${token}`;
}

export function getToken(): string {
  const tokenName = 'TELEGRAM_TOKEN';
  const unverifiedToken = process.env[tokenName];
  return unverifiedToken;
}
import * as Express from 'express';
import * as path from 'path';
import { setupBot, setupWebhook } from './elmegram.js';
const Bot = require('./bot.js')

startServer(Express())

async function startServer(app: Express) {
  // Static website
  app.use(Express.static(path.join(__dirname, '/public/')))

  const { token, handleUpdate } = await setup();
  const webhookUrl = getWebhookUrl(token);
  await setupWebhook(token, webhookUrl);
  app.use(`/bot/${token}`, handleUpdate)

  const listener = app.listen(process.env.PORT, function () {
    console.log('Your app is listening on port ' + listener.address().port)
  })
}

function getWebhookUrl(token: string): string {
  const domain = process.env.PROJECT_DOMAIN
  const host = `${domain}.glitch.me`
  const port = 8443
  return `${host}:${port}/bot/${token}`;
}

export async function setup() {
  const tokenName = 'TELEGRAM_TOKEN';
  const unverifiedToken = process.env[tokenName];
  return setupBot(unverifiedToken, Bot)
}
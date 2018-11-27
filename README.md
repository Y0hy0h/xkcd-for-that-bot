# xkcd for that bot

[![Telegram @xkcdForThatBot](https://img.shields.io/badge/Telegram-%40xkcdForThatBot-blue.svg)](https://t.me/xkcdForThatBot)

There's a relevant xkcd-for-that-bot! It helps you find [relevant xkcd] comics in Telegram.

The bot is available as [`@xkcdForThatBot`](https://t.me/xkcdForThatBot).

## Original Bot
The [original bot](https://t.me/xkcdsearch_bot) by
[GingerPlusPlus](https://github.com/GingerPlusPlus) is the inspiration for this bot.
Its code is available on [GitHub](https://github.com/GingerPlusPlus/xkcd-search-bot).

[relevant xkcd]: https://relevantxkcd.appspot.com/

# Deployment

Quick start:
```bash
npm install
npm start
```

## Build
While the build is run automatically on install, you can also run it manually.
```bash
npm run build:prod
```
This will build the bot production. This entails compiling the Elm code and then the TypeScript code. The generated JavaScript code sits in `dist/`.

## Run
After building the project, it can be run with
```bash
npm start
```
This executes the entry file `dist/index.js`.

# Development

```bash
npm run launch:dev
```
This will run the bot from the TypeScript files and disable webhooks, instead using polling. No need for an extra compilation step or setting up the server for webhooks.

```bash
npm run launch:prod
```
This will compile and start the bot, close to what `npm install && npm start` would do. Use this to reproduce the server environment more closely.
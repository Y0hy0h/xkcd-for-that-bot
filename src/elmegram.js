"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var node_fetch_1 = __importDefault(require("node-fetch"));
// Fix Elm not finding XMLHttpRequest.
var xhr2_1 = __importDefault(require("xhr2"));
global.XMLHttpRequest = xhr2_1.default;
function setupWebhook(token, url) {
    return __awaiter(this, void 0, void 0, function () {
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, node_fetch_1.default(getMethodUrl(token, 'setWebhook'), {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            url: url
                        })
                    })];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
exports.setupWebhook = setupWebhook;
function startPolling(unverifiedToken, BotElm) {
    return __awaiter(this, void 0, void 0, function () {
        function method(method) {
            return getMethodUrl(token, method);
        }
        function handleUpdates(updates) {
            return __awaiter(this, void 0, void 0, function () {
                var ids;
                return __generator(this, function (_a) {
                    ids = updates.map(function (update) {
                        handleUpdate(update);
                        return update.update_id;
                    });
                    if (ids.length) {
                        return [2 /*return*/, ids[ids.length - 1] + 1];
                    }
                    else {
                        return [2 /*return*/, null];
                    }
                    return [2 /*return*/];
                });
            });
        }
        var _a, token, handleUpdate, res, json, offset, res_1, json_1, updates, newOffset;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0: return [4 /*yield*/, setupBot(unverifiedToken, BotElm)];
                case 1:
                    _a = _b.sent(), token = _a.token, handleUpdate = _a.handleUpdate;
                    // RUN
                    console.log('Deleting potential webhook.');
                    return [4 /*yield*/, node_fetch_1.default(method('deleteWebhook'))];
                case 2:
                    res = _b.sent();
                    return [4 /*yield*/, res.json()];
                case 3:
                    json = _b.sent();
                    if (!json.ok || !json.result) {
                        console.error('Error deleting webhook:');
                        console.error(json.description);
                    }
                    console.log('Bot starting.');
                    offset = 0;
                    _b.label = 4;
                case 4:
                    if (!true) return [3 /*break*/, 11];
                    console.log("\nFetching updates starting with id " + offset + "...");
                    return [4 /*yield*/, node_fetch_1.default(method('getUpdates'), {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ offset: offset }),
                        })];
                case 5:
                    res_1 = _b.sent();
                    return [4 /*yield*/, res_1.json()];
                case 6:
                    json_1 = _b.sent();
                    if (!json_1.ok) return [3 /*break*/, 9];
                    updates = json_1.result;
                    console.log('\nReceived updates:');
                    console.log(JSON.stringify(updates, undefined, 2));
                    return [4 /*yield*/, handleUpdates(updates)];
                case 7:
                    newOffset = _b.sent();
                    offset = newOffset ? newOffset : offset;
                    return [4 /*yield*/, new Promise(function (resolve) {
                            var delay = 0;
                            setTimeout(resolve, delay);
                        })];
                case 8:
                    _b.sent();
                    return [3 /*break*/, 10];
                case 9:
                    console.error('Error fetching updates:');
                    console.error(json_1.description);
                    process.exit(2);
                    _b.label = 10;
                case 10: return [3 /*break*/, 4];
                case 11: return [2 /*return*/];
            }
        });
    });
}
exports.startPolling = startPolling;
function setupBot(unverifiedToken, BotElm) {
    return __awaiter(this, void 0, void 0, function () {
        function nullToUndefined(object, field) {
            object[field] = object[field] == null ? undefined : object[field];
            return object;
        }
        function sendMessage(sendMessage) {
            return __awaiter(this, void 0, void 0, function () {
                var res, json;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            [
                                "parse_mode",
                                "reply_to_message_id",
                                "reply_markup"
                            ].forEach(function (field) {
                                nullToUndefined(sendMessage, field);
                            });
                            return [4 /*yield*/, node_fetch_1.default(baseUrl + 'sendMessage', {
                                    method: 'POST',
                                    headers: { 'Content-Type': 'application/json' },
                                    body: JSON.stringify(sendMessage),
                                })];
                        case 1:
                            res = _a.sent();
                            return [4 /*yield*/, res.json()];
                        case 2:
                            json = _a.sent();
                            if (!json.ok) {
                                console.error('\nSending message failed. Wanted to send:');
                                console.error(JSON.stringify(sendMessage, undefined, 2));
                                console.error('Received error:');
                                console.error(JSON.stringify(json, undefined, 2));
                            }
                            else {
                                console.log('\nSuccessfully sent message:');
                                console.log(JSON.stringify(sendMessage, undefined, 2));
                            }
                            return [2 /*return*/];
                    }
                });
            });
        }
        function answerInlineQuery(inlineQuery) {
            return __awaiter(this, void 0, void 0, function () {
                var res, json;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            ["cache_time", "is_personal", "next_offset"].forEach(function (field) {
                                nullToUndefined(inlineQuery, field);
                            });
                            inlineQuery.results.forEach(function (result) {
                                if (result.type == "article") {
                                    [
                                        "description",
                                        "url",
                                        "hide_url",
                                        "thumb_url",
                                        "thumb_width",
                                        "thumb_height",
                                        "reply_markup"
                                    ].forEach(function (field) {
                                        nullToUndefined(result, field);
                                    });
                                    if (result.input_message_content &&
                                        result.input_message_content.parse_mode == null) {
                                        result.input_message_content.parse_mode = undefined;
                                    }
                                }
                            });
                            return [4 /*yield*/, node_fetch_1.default(baseUrl + 'answerInlineQuery', {
                                    method: 'POST',
                                    headers: { 'Content-Type': 'application/json' },
                                    body: JSON.stringify(inlineQuery),
                                })];
                        case 1:
                            res = _a.sent();
                            return [4 /*yield*/, res.json()];
                        case 2:
                            json = _a.sent();
                            if (!json.ok) {
                                console.error('\nAnswering inline query failed. Wanted to send:');
                                console.error(JSON.stringify(inlineQuery, undefined, 2));
                                console.error('Received error:');
                                console.error(JSON.stringify(json, undefined, 2));
                            }
                            else {
                                console.log('\nSuccessfully answered inline query:');
                                console.log(JSON.stringify(inlineQuery, undefined, 2));
                            }
                            return [2 /*return*/];
                    }
                });
            });
        }
        function answerCallbackQuery(callbackQuery) {
            return __awaiter(this, void 0, void 0, function () {
                var res, json;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            [
                                "text",
                                "url"
                            ].forEach(function (field) {
                                nullToUndefined(callbackQuery, field);
                            });
                            return [4 /*yield*/, node_fetch_1.default(baseUrl + 'answerCallbackQuery', {
                                    method: 'POST',
                                    headers: { 'Content-Type': 'application/json' },
                                    body: JSON.stringify(callbackQuery),
                                })];
                        case 1:
                            res = _a.sent();
                            return [4 /*yield*/, res.json()];
                        case 2:
                            json = _a.sent();
                            if (!json.ok) {
                                console.error('\nAnswering callback query failed. Wanted to send:');
                                console.error(JSON.stringify(callbackQuery, undefined, 2));
                                console.error('Received error:');
                                console.error(JSON.stringify(json, undefined, 2));
                            }
                            else {
                                console.log('\nSuccessfully answered callback query:');
                                console.log(JSON.stringify(callbackQuery, undefined, 2));
                            }
                            return [2 /*return*/];
                    }
                });
            });
        }
        var _a, user, token, baseUrl, bot;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    // SETUP TOKEN
                    console.log('Checking token...');
                    return [4 /*yield*/, verifyToken(unverifiedToken)];
                case 1:
                    _a = _b.sent(), user = _a.user, token = _a.token;
                    console.log("Token valid for bot '" + user.first_name + "'.");
                    baseUrl = getBaseUrl(token);
                    // SETUP ELM
                    // Fill in undefined fields with null to help Elm detect them
                    // and prevent it from crashing.
                    user.last_name = user.last_name || null;
                    user.username = user.username || null;
                    user.language_code = user.language_code || null;
                    bot = BotElm.Elm.Main.init({
                        flags: user
                    });
                    bot.ports.errorPort.subscribe(function (errorMessage) {
                        console.error(errorMessage);
                    });
                    bot.ports.methodPort.subscribe(function (methods) {
                        var _this = this;
                        methods.reduce(function (promise, method) { return __awaiter(_this, void 0, void 0, function () {
                            return __generator(this, function (_a) {
                                switch (_a.label) {
                                    case 0: return [4 /*yield*/, promise];
                                    case 1:
                                        _a.sent();
                                        switch (method.method) {
                                            case "sendMessage":
                                                return [2 /*return*/, sendMessage(method.content)];
                                            case "answerInlineQuery":
                                                return [2 /*return*/, answerInlineQuery(method.content)];
                                            case "answerCallbackQuery":
                                                return [2 /*return*/, answerCallbackQuery(method.content)];
                                        }
                                        return [2 /*return*/];
                                }
                            });
                        }); }, Promise.resolve());
                    });
                    return [2 /*return*/, { token: token, handleUpdate: bot.ports.incomingUpdatePort.send }];
            }
        });
    });
}
exports.setupBot = setupBot;
function verifyToken(token) {
    return __awaiter(this, void 0, void 0, function () {
        function cancelWithError(error, token) {
            console.error("Could not verify the token" + (token ? " '" + token + "'" : '') + ".");
            console.error('Explanation:');
            console.error(error);
        }
        var res, json, user;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    if (!token) {
                        cancelWithError("The provided token was empty. Please provide a valid Telegram bot token.");
                    }
                    return [4 /*yield*/, node_fetch_1.default(getBaseUrl(token) + 'getMe')];
                case 1:
                    res = _a.sent();
                    return [4 /*yield*/, res.json()];
                case 2:
                    json = _a.sent();
                    if (!json.ok) {
                        cancelWithError(json.description, token);
                        throw new Error("Error verifying token.");
                    }
                    else {
                        user = json.result;
                        return [2 /*return*/, { user: user, token: token }];
                    }
                    return [2 /*return*/];
            }
        });
    });
}
function getBaseUrl(token) {
    return "https://api.telegram.org/bot" + token + "/";
}
function getMethodUrl(token, method) {
    return getBaseUrl(token) + method;
}
//# sourceMappingURL=elmegram.js.map
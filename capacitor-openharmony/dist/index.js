"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.add = add;
exports.copy = copy;
exports.update = update;
exports.open = open;
exports.run = run;
const add_1 = require("./add");
const sync_1 = require("./sync");
const run_1 = require("./run");
async function add(config) {
    await (0, add_1.addOpenHarmony)(config);
}
async function copy(config) {
    await (0, sync_1.sync)(config);
}
async function update(config) {
    console.log('Update command not implemented yet (plugins)');
}
async function open(config) {
    console.log('Open command not implemented yet (DevEco Studio)');
}
async function run(config) {
    await (0, run_1.run)();
}

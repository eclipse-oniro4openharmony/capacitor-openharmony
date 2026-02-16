"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.addOpenHarmony = addOpenHarmony;
const fs_extra_1 = require("fs-extra");
const path_1 = require("path");
const common_1 = require("./common");
async function addOpenHarmony(config) {
    const projectRoot = process.env.CAPACITOR_ROOT_DIR || process.cwd();
    const platformDir = (0, path_1.join)(projectRoot, 'openharmony');
    if ((0, fs_extra_1.existsSync)(platformDir)) {
        console.log('OpenHarmony platform already exists.');
        return;
    }
    console.log('Adding OpenHarmony platform...');
    const templateDir = (0, path_1.join)(__dirname, '../assets/native-template');
    try {
        await (0, fs_extra_1.copy)(templateDir, platformDir);
        console.log('Template copied.');
        if ((config === null || config === void 0 ? void 0 : config.appId) && (config === null || config === void 0 ? void 0 : config.appName)) {
            await (0, common_1.updateAppJson5)(projectRoot, config.appId, config.appName);
            console.log('App configuration updated.');
        }
    }
    catch (e) {
        console.error('Failed to add OpenHarmony platform:', e);
    }
}

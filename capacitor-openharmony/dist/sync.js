"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sync = sync;
const fs_extra_1 = require("fs-extra");
const path_1 = require("path");
async function sync(config) {
    const projectRoot = process.cwd();
    const webDir = config.webDir || 'dist';
    const src = (0, path_1.join)(projectRoot, webDir);
    const dest = (0, path_1.join)(projectRoot, 'openharmony/entry/src/main/resources/rawfile/www');
    console.log(`Syncing ${src} to ${dest}...`);
    if (!(0, fs_extra_1.existsSync)(src)) {
        console.error(`Web directory ${src} does not exist. Did you build your web app?`);
        return;
    }
    try {
        // Clean destination? Maybe not needed as copy overwrites
        await (0, fs_extra_1.mkdirp)(dest);
        await (0, fs_extra_1.copy)(src, dest);
        console.log('Web assets synced.');
        await generatePluginRegistry(projectRoot);
    }
    catch (e) {
        console.error('Sync failed:', e);
    }
}
async function generatePluginRegistry(projectRoot) {
    console.log('Generating PluginRegistry...');
    // TODO: Scan node_modules for capacitor plugins with openharmony support
    // For now, we only support the hardcoded ones or empty.
    const registryPath = (0, path_1.join)(projectRoot, 'openharmony/entry/src/main/ets/capacitor/PluginRegistry.ets');
    const content = `
import { CapacitorPlugin } from './CapacitorPlugin';

export class PluginRegistry {
  private plugins: Map<string, CapacitorPlugin> = new Map();

  constructor() {
    this.registerPlugins();
  }

  private registerPlugins() {
    // TODO: Auto-generated plugin registration
    // this.plugins.set('PluginId', new PluginClass());
  }

  getPlugin(pluginId: string): CapacitorPlugin | undefined {
    return this.plugins.get(pluginId);
  }
}
`;
    await (0, fs_extra_1.writeFile)(registryPath, content);
    console.log('PluginRegistry.ets generated.');
}

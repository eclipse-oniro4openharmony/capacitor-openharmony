import { CapacitorConfig } from '@capacitor/cli';
import { readJson, writeJson } from 'fs-extra';
import { join } from 'path';

export interface OpenHarmonyConfig {
    appId: string;
    appName: string;
    webDir: string;
}

export async function getCapacitorConfig(): Promise<CapacitorConfig | null> {
    try {
        const configPath = join(process.cwd(), 'capacitor.config.ts');
        // Using dynamic import for ts config or require for json
        // For simplicity in this environment, we might need a more robust config loader
        // But let's assume standard capacitor CLI usage where config is available
        // Actually, @capacitor/cli might not expose a simple config loader for plugins.
        // We will implement a basic reader for now.
        return require(join(process.cwd(), 'capacitor.config.json'));
    } catch (e) {
        try {
            // Fallback for ts config - in a real plugin we'd use capacitor's config loader
            // For this POC, we'll try to read capacitor.config.json if ts fails
            // or just mock it if we are running in the demo app which has ts.
            // NOTE: compiled CLI won't run TS directly.
            // practical approach: expect capacitor.config.json or parse basic TS
            console.warn('Could not read capacitor.config.json, manual config might be needed');
            return null;
        } catch (e2) {
            return null;
        }
    }
}

export async function updateAppJson5(projectRoot: string, appId: string, appName: string) {
    const appJsonPath = join(projectRoot, 'openharmony', 'AppScope', 'app.json5');
    try {
        // json5 is not strict json, so standard require/JSON.parse might fail if it has comments.
        // However, native-template app.json5 is usually simple.
        // We'll use fs-extra to read as text and replace regex for safety if we don't want a json5 parser dep.
        const fs = require('fs-extra');
        let content = await fs.readFile(appJsonPath, 'utf8');

        // Simple regex replacement to preserve comments/formatting if possible
        content = content.replace(/"bundleName":\s*".*?"/, `"bundleName": "${appId}"`);
        content = content.replace(/"label":\s*".*?"/, `"label": "$string:app_name"`); // Usually points to resource

        // Also need to update string resource for app_name
        const stringResPath = join(projectRoot, 'openharmony', 'AppScope', 'resources', 'base', 'element', 'string.json');
        const strings = await fs.readJson(stringResPath);
        const appNameEntry = strings.string.find((e: any) => e.name === 'app_name');
        if (appNameEntry) {
            appNameEntry.value = appName;
        } else {
            strings.string.push({ name: 'app_name', value: appName });
        }
        await fs.writeJson(stringResPath, strings, { spaces: 2 });

        await fs.writeFile(appJsonPath, content);
    } catch (e) {
        console.error('Error updating AppScope/app.json5', e);
    }
}

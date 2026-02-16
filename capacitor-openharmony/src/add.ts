import { copy, existsSync, mkdirp } from 'fs-extra';
import { join } from 'path';
import { updateAppJson5 } from './common';
import { CapacitorConfig } from '@capacitor/cli';

export async function addOpenHarmony(config: CapacitorConfig) {
    const projectRoot = process.env.CAPACITOR_ROOT_DIR || process.cwd();
    const platformDir = join(projectRoot, 'openharmony');

    if (existsSync(platformDir)) {
        console.log('OpenHarmony platform already exists.');
        return;
    }

    console.log('Adding OpenHarmony platform...');
    const templateDir = join(__dirname, '../assets/native-template');

    try {
        await copy(templateDir, platformDir);
        console.log('Template copied.');

        if (config?.appId && config?.appName) {
            await updateAppJson5(projectRoot, config.appId, config.appName);
            console.log('App configuration updated.');
        }
    } catch (e) {
        console.error('Failed to add OpenHarmony platform:', e);
    }
}

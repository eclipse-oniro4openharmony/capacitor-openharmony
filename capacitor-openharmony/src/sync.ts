import { copy, existsSync, mkdirp, writeFile } from 'fs-extra';
import { join } from 'path';

export async function sync(config: any) {
  const projectRoot = process.env.CAPACITOR_ROOT_DIR || process.cwd();
  const webDir = config.webDir || 'dist';

  const src = join(projectRoot, webDir);
  const dest = join(projectRoot, 'openharmony/entry/src/main/resources/rawfile/www');

  console.log(`Syncing ${src} to ${dest}...`);

  if (!existsSync(src)) {
    console.error(`Web directory ${src} does not exist. Did you build your web app?`);
    return;
  }

  try {
    // Clean destination? Maybe not needed as copy overwrites
    await mkdirp(dest);
    await copy(src, dest);
    console.log('Web assets synced.');

    // await generatePluginRegistry(projectRoot);
  } catch (e) {
    console.error('Sync failed:', e);
  }
}

async function generatePluginRegistry(projectRoot: string) {
  console.log('Generating PluginRegistry...');
  // TODO: Scan node_modules for capacitor plugins with openharmony support
  // For now, we only support the hardcoded ones or empty.

  const registryPath = join(projectRoot, 'openharmony/entry/src/main/ets/capacitor/PluginRegistry.ets');
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
  await writeFile(registryPath, content);
  console.log('PluginRegistry.ets generated.');
}

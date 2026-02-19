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

    await updateAppName(projectRoot, config.appName);
    await generatePluginRegistry(projectRoot);
  } catch (e) {
    console.error('Sync failed:', e);
  }
}

async function updateAppName(projectRoot: string, appName: string) {
  const stringJsonPath = join(projectRoot, 'openharmony/entry/src/main/resources/base/element/string.json');
  if (!existsSync(stringJsonPath)) {
    console.warn(`string.json not found at ${stringJsonPath}. Skipping App Name sync.`);
    return;
  }

  try {
    const fs = require('fs-extra');
    const content = await fs.readJson(stringJsonPath);

    let updated = false;
    if (content.string) {
      const labelItem = content.string.find((item: any) => item.name === 'EntryAbility_label');
      if (labelItem) {
        labelItem.value = appName;
        updated = true;
      }
    }

    if (updated) {
      await fs.writeJson(stringJsonPath, content, { spaces: 2 });
      console.log(`Updated App Name to "${appName}" in string.json`);
    } else {
      console.warn('EntryAbility_label not found in string.json');
    }
  } catch (e) {
    console.error('Failed to update App Name:', e);
  }
}

async function generatePluginRegistry(projectRoot: string) {
  console.log('Generating PluginRegistry...');

  const packageJsonPath = join(projectRoot, 'package.json');
  if (!existsSync(packageJsonPath)) {
    console.error(`package.json not found at ${packageJsonPath}`);
    return;
  }

  const packageJson = await import(packageJsonPath);
  const dependencies = { ...packageJson.dependencies, ...packageJson.devDependencies };
  const plugins: any[] = [];

  for (const depName of Object.keys(dependencies)) {
    try {
      const depPackagePath = join(projectRoot, 'node_modules', depName, 'package.json');
      if (!existsSync(depPackagePath)) {
        continue;
      }

      const depPackage = await import(depPackagePath);
      if (depPackage.capacitor?.openharmony) {
        plugins.push({
          name: depName,
          ...depPackage.capacitor.openharmony
        });
      }
    } catch (e) {
      // ignore
    }
  }

  // Check for local plugins or special overrides
  const registryPath = join(projectRoot, 'openharmony/entry/src/main/ets/capacitor/PluginRegistry.ets');
  const pluginsPath = join(projectRoot, 'openharmony/entry/src/main/ets/capacitor/plugins');

  // Ensure plugins directory exists
  await mkdirp(pluginsPath);

  const imports: string[] = [];
  const registrations: string[] = [];

  for (const p of plugins) {
    if (p.src) {
      // Copy the plugin source file
      const pluginSrcAbsPath = join(projectRoot, 'node_modules', p.name, p.src);
      const pluginDestPath = join(pluginsPath, p.src);

      if (existsSync(pluginSrcAbsPath)) {
        await copy(pluginSrcAbsPath, pluginDestPath);
        console.log(`Copied ${p.name} source to ${pluginDestPath}`);

        // Assume className is derived from filename if not provided, or we can parse it.
        // For now, let's assume the class name is standard PascalCase of the plugin name + "Plugin"
        // Or we can try to find the class export in the file content? 
        // For MVP, let's stick to the convention: Filename "Device.ets" -> class "DevicePlugin"
        // AND we also need to know the import path.
        // Import path will be `./plugins/${filename_without_ext}`

        const filename = p.src.replace('.ets', '');
        const className = `${filename}Plugin`; // Convention

        imports.push(`import { ${className} } from './plugins/${filename}';`);
        registrations.push(`this.plugins.set('${filename}', new ${className}(this.bridge, this.context));`);
      } else {
        console.warn(`Plugin source not found for ${p.name} at ${pluginSrcAbsPath}`);
      }
    }
  }

  const content = `import { CapacitorPlugin } from './CapacitorPlugin';
import { CapacitorBridge } from './CapacitorBridge';
import { PluginHeader, PluginMethod } from './BridgeInterfaces';
import { common } from '@kit.AbilityKit';
${imports.join('\n')}

export class PluginRegistry {
  private plugins: Map<string, CapacitorPlugin> = new Map();
  private bridge: CapacitorBridge;
  private context: common.UIAbilityContext;

  constructor(bridge: CapacitorBridge, context: common.UIAbilityContext) {
    this.bridge = bridge;
    this.context = context;
    this.registerPlugins();
  }

  private registerPlugins() {
    ${registrations.join('\n    ')}
  }

  getPlugin(pluginId: string): CapacitorPlugin | undefined {
    return this.plugins.get(pluginId);
  }

  getPluginHeaders(): PluginHeader[] {
    let headers: PluginHeader[] = [];
    this.plugins.forEach((plugin) => {
      headers.push({
        name: plugin.getPluginId(),
        methods: plugin.getMethods().map((m): PluginMethod => {
          return { name: m, rtype: 'promise' };
        })
      });
    });
    return headers;
  }
}
`;
  await writeFile(registryPath, content);
  console.log('PluginRegistry.ets generated.');
}

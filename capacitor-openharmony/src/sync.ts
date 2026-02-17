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

    await generatePluginRegistry(projectRoot);
  } catch (e) {
    console.error('Sync failed:', e);
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

  // Also check for local plugins or special overrides if needed
  // For the MVP, we assume plugins are in node_modules and have the entry.

  const registryPath = join(projectRoot, 'openharmony/entry/src/main/ets/capacitor/PluginRegistry.ets');

  const imports = plugins.map(p => {
    // We assume the plugin exposes a class matching its name or defined in config
    // Actually, we need to know the class name. 
    // Standard capacitor defines 'android' -> 'src/main/.../SomePlugin.java' 
    // We need the class name. Let's assume the config has it or we derive it.
    // For now, let's assume 'alias' or 'className' in config, or TitleCase(package_name - @ scope).
    // Let's assume the standard: import { SomePlugin } from 'package_name';
    // But in OH, we import from the OH module.
    // The OH module alias in oh-package.json5 will be the package name usually.
    return `import { ${p.pluginClass || toPascalCase(p.name)} } from '${p.name}';`;
  }).join('\n');

  const registrations = plugins.map(p => {
    return `this.plugins.set('${p.pluginName || toPascalCase(p.name)}', new ${p.pluginClass || toPascalCase(p.name)}(this.bridge, this.context));`;
  }).join('\n    ');

  // Always include Device plugin for now as it is in the core template/project for this MVP logic 
  // until it is extracted to a separate package.
  // actually existing logic had: import { DevicePlugin } from "./plugins/Device";
  // We should preserve local plugins.

  const content = `import { CapacitorPlugin } from './CapacitorPlugin';
import { CapacitorBridge } from './CapacitorBridge';
import { common } from '@kit.AbilityKit';
import { DevicePlugin } from './plugins/Device';
import { AppPlugin } from './plugins/App';
import { NetworkPlugin } from './plugins/Network';
${imports}

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
    this.plugins.set('Device', new DevicePlugin(this.bridge, this.context));
    this.plugins.set('App', new AppPlugin(this.bridge, this.context));
    this.plugins.set('Network', new NetworkPlugin(this.bridge, this.context));
    ${registrations}
  }

  getPlugin(pluginId: string): CapacitorPlugin | undefined {
    return this.plugins.get(pluginId);
  }
}
`;
  await writeFile(registryPath, content);
  console.log('PluginRegistry.ets generated.');

  // Update oh-package.json5
  await updateOhPackage(projectRoot, plugins);
}

async function updateOhPackage(projectRoot: string, plugins: any[]) {
  const ohPackagePath = join(projectRoot, 'openharmony/entry/oh-package.json5');
  if (!existsSync(ohPackagePath)) return;

  const fs = require('fs-extra');
  let content = await fs.readFile(ohPackagePath, 'utf8');

  // Basic dependency injection
  const depStart = content.indexOf('"dependencies": {');
  if (depStart === -1) {
    console.warn('No dependencies block found in oh-package.json5');
    return;
  }

  const openBrace = content.indexOf('{', depStart);
  // Find matching closing brace (simple implementation assuming no nested braces in dependencies)
  const closeBrace = content.indexOf('}', openBrace);

  if (closeBrace === -1) {
    console.warn('Malformed oh-package.json5');
    return;
  }

  const innerContent = content.substring(openBrace + 1, closeBrace);
  // Check if we need to add plugin
  // This simple check might fail if formatting differs, but good enough for MVP
  const missingPlugins = plugins.filter(p => !innerContent.includes(`"${p.name}"`));

  if (missingPlugins.length === 0) {
    console.log('No new plugins to add to oh-package.json5');
    return;
  }

  const newDeps = missingPlugins.map(p => {
    const relativePath = `file:../../node_modules/${p.name}/${p.src || 'openharmony'}`;
    return `    "${p.name}": "${relativePath}"`;
  });

  const hasContent = innerContent.trim().length > 0;
  const insertText = (hasContent ? ',' : '') + '\n' + newDeps.join(',\n') + '\n  ';

  content = content.slice(0, closeBrace) + insertText + content.slice(closeBrace);

  await fs.writeFile(ohPackagePath, content);
  console.log(`Updated oh-package.json5 with ${missingPlugins.length} new plugins.`);
}

function toPascalCase(str: string) {
  let clean = str;
  if (str.startsWith('@')) {
    const parts = str.split('/');
    if (parts.length > 1) {
      clean = parts[1];
    }
  }
  return clean.replace(/(^\w|-\w)/g, clearAndUpper).replace(/[^\w]/g, '');
}

function clearAndUpper(text: string) {
  return text.replace(/-/, "").toUpperCase();
}

import { CapacitorPlugin } from "./CapacitorPlugin";
import { CapacitorBridge } from "./CapacitorBridge";
import { common } from "@kit.AbilityKit";
import { DevicePlugin } from "./plugins/Device";

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
    this.plugins.set("Device", new DevicePlugin(this.bridge, this.context));
  }

  getPlugin(pluginId: string): CapacitorPlugin | undefined {
    return this.plugins.get(pluginId);
  }
}

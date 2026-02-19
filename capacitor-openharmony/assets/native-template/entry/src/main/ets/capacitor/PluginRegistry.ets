import { CapacitorPlugin } from "./CapacitorPlugin";
import { CapacitorBridge } from "./CapacitorBridge";
import { PluginHeader, PluginMethod } from "./BridgeInterfaces";
import { common } from "@kit.AbilityKit";

export class PluginRegistry {
  private plugins: Map<string, CapacitorPlugin> = new Map();
  private bridge: CapacitorBridge;
  private context: common.UIAbilityContext;

  constructor(bridge: CapacitorBridge, context: common.UIAbilityContext) {
    this.bridge = bridge;
    this.context = context;
    this.registerPlugins();
  }

  private registerPlugins() {}

  getPlugin(pluginId: string): CapacitorPlugin | undefined {
    return this.plugins.get(pluginId);
  }

  getPluginHeaders(): PluginHeader[] {
    let headers: PluginHeader[] = [];
    this.plugins.forEach((plugin) => {
      headers.push({
        name: plugin.getPluginId(),
        methods: plugin.getMethods().map((m: string): PluginMethod => {
          return { name: m, rtype: "promise" };
        }),
      });
    });
    return headers;
  }
}

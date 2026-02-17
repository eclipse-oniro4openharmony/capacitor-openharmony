import { common } from "@kit.AbilityKit";
import { CapacitorBridge } from "./CapacitorBridge";
import { PluginCall } from "./PluginCall";

export abstract class CapacitorPlugin {
  protected bridge: CapacitorBridge;
  protected context: common.UIAbilityContext;

  constructor(bridge: CapacitorBridge, context: common.UIAbilityContext) {
    this.bridge = bridge;
    this.context = context;
  }

  load(): void {}

  notifyListeners(eventName: string, data: Object): void {
    this.bridge.notifyListeners(this.getPluginId(), eventName, data);
  }

  abstract getPluginId(): string;

  getMethods(): string[] {
    return [];
  }

  addListener(call: PluginCall): void {
    // Default implementation: just resolve.
    // The bridge handles the JS side event registration ?
    // Actually, in Capacitor, the native plugin 'addListener' is called to let the native side know
    // that someone is listening, so it can start emitting events if it was lazy.
    // For standard events, we might not need to do anything.
    call.resolve();
  }

  removeListener(call: PluginCall): void {
    call.resolve();
  }

  removeAllListeners(call: PluginCall): void {
    call.resolve();
  }
}

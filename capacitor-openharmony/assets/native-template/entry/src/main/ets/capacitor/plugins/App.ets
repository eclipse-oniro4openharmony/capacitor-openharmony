import { CapacitorPlugin } from "../CapacitorPlugin";
import { PluginCall } from "../PluginCall";
import { common } from "@kit.AbilityKit";

export class AppPlugin extends CapacitorPlugin {
  getPluginId(): string {
    return "App";
  }

  getMethods(): string[] {
    return ["exitApp", "addListener", "removeListener", "removeAllListeners"];
  }

  exitApp(call: PluginCall) {
    try {
      this.context.terminateSelf();
    } catch (e) {
      // ignore
    }
    call.resolve();
  }

  addListener(call: PluginCall) {
    call.resolve();
  }

  removeListener(call: PluginCall) {
    call.resolve();
  }

  removeAllListeners(call: PluginCall) {
    call.resolve();
  }
}

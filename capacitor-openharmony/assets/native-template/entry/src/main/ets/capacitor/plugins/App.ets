import { CapacitorPlugin } from "../CapacitorPlugin";
import { PluginCall } from "../PluginCall";
import { common } from "@kit.AbilityKit";

export class AppPlugin extends CapacitorPlugin {
  getPluginId(): string {
    return "App";
  }

  exitApp(call: PluginCall) {
    this.context.terminateSelf();
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

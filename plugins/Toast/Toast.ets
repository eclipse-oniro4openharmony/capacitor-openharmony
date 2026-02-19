import { CapacitorPlugin } from "../CapacitorPlugin";
import { PluginCall } from "../PluginCall";
import promptAction from "@ohos.promptAction";

export class ToastPlugin extends CapacitorPlugin {
  getPluginId(): string {
    return "Toast";
  }

  getMethods(): string[] {
    return ["show"];
  }

  async show(call: PluginCall) {
    const text = call.getString("text");
    const duration = call.getString("duration") === "long" ? 3500 : 2000;

    if (text) {
      try {
        promptAction.showToast({
          message: text,
          duration: duration,
        });
        call.resolve();
      } catch (error) {
        call.reject(error.message);
      }
    } else {
      call.reject("Must provide text");
    }
  }
}

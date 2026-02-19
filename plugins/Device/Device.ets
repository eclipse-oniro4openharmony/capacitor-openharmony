import { CapacitorPlugin } from "../CapacitorPlugin";
import { PluginCall } from "../PluginCall";
import deviceInfo from "@ohos.deviceInfo";
import i18n from "@ohos.i18n";

export class DevicePlugin extends CapacitorPlugin {
  getPluginId(): string {
    return "Device";
  }

  getMethods(): string[] {
    return ["getInfo", "getId", "getLanguageCode"];
  }

  async getLanguageCode(call: PluginCall) {
    class LanguageResult {
      value: string = "";
    }
    let val = i18n.getSystemLanguage();
    let res: LanguageResult = { value: val };
    call.resolve(res);
  }

  async getInfo(call: PluginCall) {
    class DeviceInfo {
      model: string = "";
      platform: string = "";
      osVersion: string = "";
      manufacturer: string = "";
      isVirtual: boolean = false;
      memUsed: number = 0;
      realDiskFree: number = 0;
      realDiskTotal: number = 0;
      webViewVersion: string = "";
    }

    let info: DeviceInfo = {
      model: deviceInfo.marketName,
      platform: "openharmony",
      osVersion: deviceInfo.osFullName,
      manufacturer: deviceInfo.manufacture,
      isVirtual:
        deviceInfo.marketName.includes("Emulator") || deviceInfo.marketName.includes("Simulator"),
      memUsed: 0,
      realDiskFree: 0,
      realDiskTotal: 0,
      webViewVersion: "N/A",
    };
    call.resolve(info);
  }

  async getId(call: PluginCall) {
    // TODO: Implement proper UUID generation or retrieval
    class DeviceId {
      uuid: string = "";
    }
    let id: DeviceId = { uuid: "test-uuid" };
    call.resolve(id);
  }
}

import { CapacitorPlugin } from "../CapacitorPlugin";
import { PluginCall } from "../PluginCall";
import connection from "@ohos.net.connection";
import { BusinessError } from "@kit.BasicServicesKit";

class NetworkStatus {
  connected: boolean = false;
  connectionType: string = "none";
}

export class NetworkPlugin extends CapacitorPlugin {
  private netConnection: connection.NetConnection | null = null;

  getPluginId(): string {
    return "Network";
  }

  getMethods(): string[] {
    return ["getStatus", "addListener", "removeListener", "removeAllListeners"];
  }

  load() {
    this.startMonitoring();
  }

  async getStatus(call: PluginCall) {
    try {
      let netHandle = connection.getDefaultNetSync();
      if (!netHandle || netHandle.netId === 0) {
        let status = new NetworkStatus();
        status.connected = false;
        status.connectionType = "none";
        call.resolve(status);
        return;
      }

      let caps = await connection.getNetCapabilities(netHandle);
      let type = this.getConnectionType(caps);
      let status = new NetworkStatus();
      status.connected = true;
      status.connectionType = type;
      call.resolve(status);
    } catch (e) {
      let status = new NetworkStatus();
      status.connected = false;
      status.connectionType = "none";
      call.resolve(status);
    }
  }

  private startMonitoring() {
    if (this.netConnection) return;
    this.netConnection = connection.createNetConnection();

    this.netConnection.register((error: BusinessError) => {
      // log error
    });

    this.netConnection.on("netAvailable", (data) => {
      this.updateStatus(true);
    });

    this.netConnection.on("netLost", (data) => {
      this.updateStatus(false);
    });

    this.netConnection.on("netUnavailable", (data) => {
      this.updateStatus(false);
    });
  }

  private async updateStatus(connected: boolean) {
    // We need to re-fetch capabilities to determine type if connected
    let type = "none";
    if (connected) {
      try {
        let netHandle = connection.getDefaultNetSync();
        if (netHandle && netHandle.netId !== 0) {
          let caps = await connection.getNetCapabilities(netHandle);
          type = this.getConnectionType(caps);
        }
      } catch (e) {}
    }
    let status = new NetworkStatus();
    status.connected = connected;
    status.connectionType = type;
    this.notifyListeners("networkStatusChange", status);
  }

  private getConnectionType(caps: connection.NetCapabilities): string {
    if (caps.bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
      return "wifi";
    } else if (caps.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR)) {
      return "cellular";
    } else if (caps.bearerTypes.includes(connection.NetBearType.BEARER_ETHERNET)) {
      return "ethernet";
    }
    return "unknown";
  }
}

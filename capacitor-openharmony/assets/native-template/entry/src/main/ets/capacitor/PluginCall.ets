import { CapacitorBridge } from './CapacitorBridge';
import { PluginErrorData } from './BridgeInterfaces';

export class PluginCall {
  pluginId: string;
  methodName: string;
  callbackId: string;
  options: Record<string, Object>;
  bridge: CapacitorBridge;

  constructor(bridge: CapacitorBridge, pluginId: string, methodName: string, callbackId: string, options: Record<string, Object>) {
    this.bridge = bridge;
    this.pluginId = pluginId;
    this.methodName = methodName;
    this.callbackId = callbackId;
    this.options = options;
  }

  getString(key: string): string {
    let value = this.options[key];
    if (typeof value === 'string') {
        return value;
    }
    return "";
  }

  getObject(key: string): Object | null {
    let value = this.options[key];
    if (typeof value === 'object' && value !== null) {
        return value;
    }
    return null;
  }
  
  getBoolean(key: string): boolean {
    return this.options[key] === true;
  }

  getNumber(key: string): number {
    let value = this.options[key];
    if (typeof value === 'number') {
        return value;
    }
    return 0;
  }

  resolve(data?: Object) {
    this.bridge.sendResult(this.callbackId, data ?? ({} as Record<string, Object>), true);
  }

  reject(message: string, code?: string, error?: Object) {
    let errData: PluginErrorData = {
        message: message
    };
    if (code) errData.code = code;
    if (error) errData.error = error;
    
    this.bridge.sendResult(this.callbackId, errData, false);
  }
}

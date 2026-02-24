export interface BridgeMessage {
  callbackId: string;
  pluginId: string;
  methodName: string;
  options?: Record<string, Object>;
}

export interface PluginResult {
  pluginId: string;
  methodName: string;
  callbackId: string;
  success: boolean;
  data: Object;
  error?: Object | null;
  save?: boolean;
}

export interface ResponseHeader {
  header: string;
  value: string;
}

export interface HarmonyProxy {
  postMessage: (jsonMessage: string) => void;
}

export interface AppState {
  isActive: boolean;
}

export interface AppUrl {
  url: string;
}

export interface PluginErrorData {
  message: string;
  code?: string;
  error?: Object;
}

export interface PluginMethod {
  name: string;
  rtype?: "promise" | "callback";
}

export interface PluginHeader {
  name: string;
  methods: PluginMethod[];
}

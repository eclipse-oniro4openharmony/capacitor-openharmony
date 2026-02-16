import { webview } from "@kit.ArkWeb";

import { common } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { PluginCall } from "./PluginCall";
import { CapacitorPlugin } from "./CapacitorPlugin";
import { PluginRegistry } from "./PluginRegistry";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { BridgeMessage, PluginResult, ResponseHeader, HarmonyProxy } from "./BridgeInterfaces";

const TAG = "CapacitorBridge";
const DOMAIN = 0x0000;

export let bridgeInstance: CapacitorBridge | null = null;

export class CapacitorBridge {
  private controller: webview.WebviewController;
  private context: common.UIAbilityContext;
  private registry: PluginRegistry;

  constructor(controller: webview.WebviewController, context: common.UIAbilityContext) {
    this.controller = controller;
    this.context = context;
    this.registry = new PluginRegistry(this, this.context);
    bridgeInstance = this;
  }

  // The object exposed to the WebView
  getProxyObject(): HarmonyProxy {
    let proxy: HarmonyProxy = {
      postMessage: (jsonMessage: string) => {
        this.handleMessage(jsonMessage);
      },
    };
    return proxy;
  }

  private handleMessage(jsonStr: string) {
    try {
      hilog.info(DOMAIN, TAG, "Received message: %{public}s", jsonStr);
      let message: BridgeMessage = JSON.parse(jsonStr) as BridgeMessage;

      let callbackId = message.callbackId;
      let pluginId = message.pluginId;
      let methodName = message.methodName;
      let options = message.options;

      if (!pluginId || !methodName) {
        hilog.error(DOMAIN, TAG, "Invalid message format");
        return;
      }

      this.routeToPlugin(pluginId, methodName, options || {}, callbackId);
    } catch (e) {
      hilog.error(DOMAIN, TAG, "JSON Parse Error: %{public}s", JSON.stringify(e));
    }
  }

  private routeToPlugin(
    pluginId: string,
    methodName: string,
    options: Record<string, Object>,
    callbackId: string,
  ) {
    // Phase 4: Registry-based dispatch
    hilog.info(
      DOMAIN,
      TAG,
      "Routing to plugin: %{public}s method: %{public}s",
      pluginId,
      methodName,
    );

    // Helper class for error messages to satisfy ArkTS strict mode
    class BridgeError {
      message: string = "";
    }

    let plugin = this.registry.getPlugin(pluginId);
    if (!plugin) {
      hilog.error(DOMAIN, TAG, "Plugin not found: %{public}s", pluginId);
      let error = new BridgeError();
      error.message = `Plugin ${pluginId} not found`;
      this.sendResult(callbackId, error, false);
      return;
    }

    // Dynamic method invocation
    // In ArkTS, accessing methods by string index on class instances is restricted.
    // We cast to any to allow indexing, and invoke directly to preserve 'this' (if possible)
    // or use the method from the record.
    // Since 'call' and 'apply' are forbidden, we must invoke properties.

    // We can cast plugin to a type that allows indexing
    let pluginAny: Record<string, (call: PluginCall) => void> = plugin as Object as Record<
      string,
      (call: PluginCall) => void
    >;
    let func = pluginAny[methodName];

    if (typeof func === "function") {
      try {
        let call = new PluginCall(this, pluginId, methodName, callbackId, options);
        // Bind context to ensure 'this' is correct inside the plugin
        // In ArkTS, we cannot use .call().
        // We hope the method is bound or we call it as a method of the object
        pluginAny[methodName](call);
      } catch (e) {
        hilog.error(DOMAIN, TAG, "Error executing plugin method: %{public}s", JSON.stringify(e));
        let error = new BridgeError();
        error.message = `Error executing method ${methodName}`;
        this.sendResult(callbackId, error, false);
      }
    } else {
      hilog.error(DOMAIN, TAG, "Method not found: %{public}s", methodName);
      let error = new BridgeError();
      error.message = `Method ${methodName} not found`;
      this.sendResult(callbackId, error, false);
    }
  }

  sendResult(callbackId: string, data: Object, success: boolean) {
    let resultPayload: PluginResult = {
      pluginId: "PluginName", // Ideally passed through
      methodName: "MethodName",
      callbackId: callbackId,
      success: success,
      data: data,
      error: success ? null : data,
    };

    let payloadStr = JSON.stringify(resultPayload);
    let jsCode = `window.Capacitor.fromNative(${payloadStr})`;

    try {
      this.controller.runJavaScript(jsCode);
    } catch (e) {
      hilog.error(DOMAIN, TAG, "Failed to run JavaScript: %{public}s", JSON.stringify(e));
    }
  }

  notifyListeners(pluginId: string, eventName: string, data: Object) {
    let jsCode = `window.Capacitor.triggerEvent('${pluginId}', '${eventName}', ${JSON.stringify(data)})`;
    this.controller.runJavaScript(jsCode);
  }

  handleResourceRequest(event: WebResourceRequest): WebResourceResponse | null {
    if (!event) return null;

    try {
      let url = event.getRequestUrl();
      hilog.info(DOMAIN, TAG, "Intercepted request: %{public}s", url);

      if (url.startsWith("http://localhost/")) {
        try {
          let path = decodeURIComponent(url.replace("http://localhost/", ""));
          if (path === "" || path.endsWith("/")) {
            path += "index.html";
          }

          // Security check
          if (path.includes("..")) {
            let response = new WebResourceResponse();
            response.setResponseCode(403);
            response.setReasonMessage("Forbidden");
            return response;
          }

          let resourceManager = this.context.resourceManager;
          // 'www' is expected to be in rawfile
          let rawFileContent = resourceManager.getRawFileContentSync(`www/${path}`);

          let mimeType = this.getMimeType(path);
          hilog.info(
            DOMAIN,
            TAG,
            "Serving asset: %{public}s (%{public}d bytes, %{public}s)",
            path,
            rawFileContent.byteLength,
            mimeType,
          );

          let response = new WebResourceResponse();

          // Cast to ArrayBuffer to satisfy ArkTS strict checks
          let bufferData = rawFileContent.buffer.slice(
            0,
            rawFileContent.buffer.byteLength,
          ) as ArrayBuffer;

          response.setResponseData(bufferData);
          response.setResponseEncoding("utf-8");
          response.setResponseMimeType(mimeType);
          response.setResponseCode(200);
          response.setReasonMessage("OK");

          // Allow CORS
          response.setResponseHeader([
            { headerKey: "Access-Control-Allow-Origin", headerValue: "*" },
          ]);

          return response;
        } catch (error) {
          hilog.error(
            DOMAIN,
            TAG,
            "Failed to load asset or decode path: %{public}s error: %{public}s",
            url,
            JSON.stringify(error),
          );
          let response = new WebResourceResponse();
          response.setResponseCode(404);
          response.setReasonMessage("Not Found");
          return response;
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, "Error in handleResourceRequest: %{public}s", JSON.stringify(error));
    }

    return null;
  }

  private getMimeType(path: string): string {
    if (path.endsWith(".html")) return "text/html";
    if (path.endsWith(".js")) return "application/javascript";
    if (path.endsWith(".css")) return "text/css";
    if (path.endsWith(".png")) return "image/png";
    if (path.endsWith(".jpg") || path.endsWith(".jpeg")) return "image/jpeg";
    if (path.endsWith(".svg")) return "image/svg+xml";
    if (path.endsWith(".json")) return "application/json";
    return "application/octet-stream";
  }

  injectCapacitorGlobal() {
    hilog.info(DOMAIN, TAG, "Capacitor Global Injection Hook");
    let js = `
      (function() {
        console.log("Starting Capacitor OpenHarmony Bridge Injection");
        
        window.Capacitor = window.Capacitor || {};
        window.Capacitor.Plugins = window.Capacitor.Plugins || {};
        
        // 1. Define Plugin Headers (Manual for MVP, should be dynamic)
        window.Capacitor.PluginHeaders = [
          {
            name: 'Device',
            methods: [
              { name: 'getInfo', rtype: 'promise' },
              { name: 'getId', rtype: 'promise' }
            ]
          }
          // Add other plugins here
        ];

        // 2. Define Callback Management
        window.Capacitor.callbacks = window.Capacitor.callbacks || {};
        
        window.Capacitor.toNative = function(pluginId, methodName, options, storedCallback) {
           // Not used in Android bridge style, but good to have
        };

        window.Capacitor.fromNative = function(result) {
            console.log("fromNative", JSON.stringify(result));
            if (!result) return;
            
            var callback = window.Capacitor.callbacks[result.callbackId];
            if (!callback) return;

            if (result.success) {
                callback.resolve(result.data);
            } else {
                callback.reject(result.error);
            }
            
            if (!result.save) {
                delete window.Capacitor.callbacks[result.callbackId];
            }
        };

        // 3. Define nativePromise
        window.Capacitor.nativePromise = function(pluginId, methodName, options) {
            return new Promise(function(resolve, reject) {
                var callbackId = String(Date.now()) + '-' + Math.floor(Math.random() * 1000);
                window.Capacitor.callbacks[callbackId] = { resolve: resolve, reject: reject };
                
                var message = {
                    type: 'message',
                    callbackId: callbackId,
                    pluginId: pluginId,
                    methodName: methodName,
                    options: options || {}
                };
                
                if (window.androidBridge) {
                    window.androidBridge.postMessage(JSON.stringify(message));
                } else {
                    console.error("androidBridge not found");
                    reject("Bridge not found");
                }
            });
        };
        
        // 4. Define nativeCallback (for listeners)
        window.Capacitor.nativeCallback = function(pluginId, methodName, options, callback) {
             // TODO: specific implementation if needed, usually nativePromise covers it for one-off
             // For listeners, we need to handle 'save' in fromNative.
             // This is a simplified version.
             var callbackId = String(Date.now()) + '-' + Math.floor(Math.random() * 1000);
             window.Capacitor.callbacks[callbackId] = { resolve: callback, reject: console.error };
             
             var message = {
                type: 'message',
                callbackId: callbackId,
                pluginId: pluginId,
                methodName: methodName,
                options: options || {}
             };
              if (window.androidBridge) {
                    window.androidBridge.postMessage(JSON.stringify(message));
                }
             return callbackId;
        };

        console.log("Capacitor OpenHarmony Bridge Injected");
      })();
    `;

    try {
      this.controller.runJavaScript(js);
    } catch (e) {
      hilog.error(DOMAIN, TAG, "Failed to inject bridge: %{public}s", JSON.stringify(e));
    }
  }

  handleBackPressed(): boolean {
    let data: Record<string, Object> = {};
    this.notifyListeners("App", "backButton", data);
    return true;
  }
}

import { webview } from '@kit.ArkWeb';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { PluginCall } from './PluginCall';
import { CapacitorPlugin } from './CapacitorPlugin';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BridgeMessage, PluginResult, ResponseHeader, HarmonyProxy } from './BridgeInterfaces';

const TAG = 'CapacitorBridge';
const DOMAIN = 0x0000;


export let bridgeInstance: CapacitorBridge | null = null;

export class CapacitorBridge {
  private controller: webview.WebviewController;
  private context: common.UIAbilityContext;
  private plugins: Map<string, CapacitorPlugin> = new Map();

  constructor(controller: webview.WebviewController, context: common.UIAbilityContext) {
    this.controller = controller;
    this.context = context;
    bridgeInstance = this;
  }

  // The object exposed to the WebView
  getProxyObject(): HarmonyProxy {
    let proxy: HarmonyProxy = {
      postMessage: (jsonMessage: string) => {
        this.handleMessage(jsonMessage);
      }
    };
    return proxy;
  }

  private handleMessage(jsonStr: string) {
    try {
      hilog.info(DOMAIN, TAG, 'Received message: %{public}s', jsonStr);
      let message: BridgeMessage = JSON.parse(jsonStr) as BridgeMessage;
      
      let callbackId = message.callbackId;
      let pluginId = message.pluginId;
      let methodName = message.methodName;
      let options = message.options;

      if (!pluginId || !methodName) {
         hilog.error(DOMAIN, TAG, 'Invalid message format');
         return;
      }

      this.routeToPlugin(pluginId, methodName, options || {}, callbackId);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'JSON Parse Error: %{public}s', JSON.stringify(e));
    }
  }

  private routeToPlugin(pluginId: string, methodName: string, options: Record<string, Object>, callbackId: string) {
    // Phase 2: Simple echo/mock for now found plugins
    // In Phase 3/4 this will look up actual plugins
    hilog.info(DOMAIN, TAG, 'Routing to plugin: %{public}s method: %{public}s', pluginId, methodName);

    // Mock response for verification
    if (pluginId === 'Device' && methodName === 'getInfo') {
        let data: Record<string, Object> = {
            'model': 'OpenHarmony Mock',
            'platform': 'openharmony',
            'osVersion': '1.0',
            'manufacturer': 'Huawei'
        };
        this.sendResult(callbackId, data, true);
        return;
    }
    
     // For now, if not handled, return success null to simple console
     let errorData: Record<string, string> = { 'value': 'Method not implemented yet' };
     this.sendResult(callbackId, errorData, true);
  }

  sendResult(callbackId: string, data: Object, success: boolean) {
    let resultPayload: PluginResult = {
        pluginId: "PluginName", // Ideally passed through
        methodName: "MethodName",
        callbackId: callbackId,
        success: success,
        data: data,
        error: success ? null : data
    };
    
    let payloadStr = JSON.stringify(resultPayload);
    // Escape backticks or use secure injection
    // JSON.stringify should be safe enough for standard data
    let jsCode = `window.Capacitor.fromNative(${payloadStr})`;
    
    try {
        this.controller.runJavaScript(jsCode);
    } catch(e) {
        hilog.error(DOMAIN, TAG, 'Failed to run JavaScript: %{public}s', JSON.stringify(e));
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
        hilog.info(DOMAIN, TAG, 'Intercepted request: %{public}s', url);

        if (url.startsWith('http://localhost/')) {
        try {
            let path = decodeURIComponent(url.replace('http://localhost/', ''));
            if (path === '' || path.endsWith('/')) {
                path += 'index.html';
            }
            
            // Security check
            if (path.includes('..')) {
                 let response = new WebResourceResponse();
                 response.setResponseCode(403);
                 response.setReasonMessage('Forbidden');
                 return response;
            }

            let resourceManager = this.context.resourceManager;
            // 'www' is expected to be in rawfile
            let rawFileContent = resourceManager.getRawFileContentSync(`www/${path}`);
            
            let mimeType = this.getMimeType(path);
            hilog.info(DOMAIN, TAG, 'Serving asset: %{public}s (%{public}d bytes, %{public}s)', path, rawFileContent.byteLength, mimeType);

            let response = new WebResourceResponse();
            // setResponseData takes string | ArrayBuffer. Uint8Array might be problematic.
            // Using buffer ensures we pass ArrayBuffer.
            // We should ensure we pass the correct slice if it's a view, but usually it's fine from ResourceManager.
            response.setResponseData(rawFileContent.buffer);
            response.setResponseEncoding('utf-8');
            response.setResponseMimeType(mimeType);
            response.setResponseCode(200);
            response.setReasonMessage('OK');
            
            // Allow CORS
            // Fix strict type check for Header
            let headers: Array<Header> = [
                { headerKey: 'Access-Control-Allow-Origin', headerValue: '*' }
            ];
            response.setResponseHeader(headers);

            return response;
        } catch (error) {
             hilog.error(DOMAIN, TAG, 'Failed to load asset or decode path: %{public}s error: %{public}s', url, JSON.stringify(error));
             let response = new WebResourceResponse();
             response.setResponseCode(404);
             response.setReasonMessage('Not Found');
             return response;
        }
        }
    } catch (error) {
        hilog.error(DOMAIN, TAG, 'Error in handleResourceRequest: %{public}s', JSON.stringify(error));
    }
    
    return null;
  }

  private getMimeType(path: string): string {
    if (path.endsWith('.html')) return 'text/html';
    if (path.endsWith('.js')) return 'application/javascript';
    if (path.endsWith('.css')) return 'text/css';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.svg')) return 'image/svg+xml';
    if (path.endsWith('.json')) return 'application/json';
    return 'application/octet-stream';
  }
  
  injectCapacitorGlobal() {
     // Optional: In case we need to inject the core JS if it's not bundled
     // But usually Capacitor apps bundle capacitor.js
     hilog.info(DOMAIN, TAG, 'Capacitor Global Injection Hook');
  }
  
  handleBackPressed(): boolean {
      // notify listeners
      let data: Record<string, Object> = {};
      this.notifyListeners('App', 'backButton', data);
      // Return true if handled? Or let web decide?
      // Capacitor usually handles this via App plugin.
      return true; 
  }
}

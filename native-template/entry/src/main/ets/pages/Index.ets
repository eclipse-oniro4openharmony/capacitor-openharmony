import { webview } from '@kit.ArkWeb';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CapacitorBridge } from '../capacitor/CapacitorBridge';

@Entry
@Component
struct Index {
  controller: webview.WebviewController = new webview.WebviewController();
  bridge: CapacitorBridge | null = null;
  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  aboutToAppear(): void {
    // Initialize bridge
    this.bridge = new CapacitorBridge(this.controller, this.context);
  }

  build() {
    Column() {
      Web({ 
        src: 'http://localhost/index.html', 
        controller: this.controller 
      })
      .javaScriptAccess(true)
      .domStorageAccess(true)
      .fileAccess(true)
      .onInterceptRequest((event) => {
        if (this.bridge && event) {
            return this.bridge.handleResourceRequest(event.request);
        }
        return null;
      })
      .javaScriptProxy({
        object: this.bridge?.getProxyObject(),
        name: "HarmonyBridge",
        methodList: ["postMessage"],
        controller: this.controller
      })
      .onConsole((event) => {
        hilog.info(0x0000, 'WebViewConsole', 'Console event triggered');
        if (event) {
          hilog.info(0x0000, 'WebViewConsole', '%{public}s', event.message.getMessage());
          return false;
        }
        return false;
      })
      .onPageBegin(() => {
        this.bridge?.injectCapacitorGlobal();
      })
      .onPageEnd(() => {
        hilog.info(0x0000, 'WebViewStatus', 'Page load finished');
      })
      .onErrorReceive((event) => {
        if (event) {
          hilog.error(0x0000, 'WebViewError', 'Error: %{public}s, %{public}s', event.request.getRequestUrl(), event.error.getErrorInfo());
        }
      })
      .onHttpErrorReceive((event) => {
        if (event) {
          hilog.error(0x0000, 'WebViewHttpError', 'HttpError: %{public}s, %{public}d', event.request.getRequestUrl(), event.response.getResponseCode());
        }
      })
      .width('100%')
      .height('100%')
    }
  }
}
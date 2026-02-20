import { CapacitorPlugin } from "../CapacitorPlugin";
import { PluginCall } from "../PluginCall";
import { window, UIContext } from "@kit.ArkUI";
import { ComponentContent } from "@ohos.arkui.node";
import { hilog } from "@kit.PerformanceAnalysisKit";
import web_webview from "@ohos.web.webview";
import picker from "@ohos.file.picker";
import Url from "@ohos.url";

export interface FileSelectorResult {
  handleFileList(fileList: string[]): void;
}

export interface FileSelector {
  getAcceptType(): string[];
  isCapture(): boolean;
  getMode(): number;
}

export interface FileSelectorEvent {
  fileSelector: FileSelector;
  result: FileSelectorResult;
}

export class AndroidInterfaceObject {
  postMessage: (message: string) => void;
  close: () => void;
  hide: () => void;
  show: () => void;
  constructor(
    postMessage: (message: string) => void,
    close: () => void,
    hide: () => void,
    show: () => void,
  ) {
    this.postMessage = postMessage;
    this.close = close;
    this.hide = hide;
    this.show = show;
  }
}

export interface WebViewOptions {
  url: string;
  headers?: Record<string, string>;
  title?: string;
  toolbarColor?: string;
  toolbarTextColor?: string;
  toolbarType?: "navigation" | "activity" | "blank";
  showReloadButton?: boolean;
  closeModal?: boolean;
  closeModalTitle?: string;
  closeModalDescription?: string;
  closeModalOk?: string;
  closeModalCancel?: string;
  preventDeeplink?: boolean;
  enableGooglePaySupport?: boolean;
  hidden?: boolean;
}

export interface WebViewCallbacks {
  pageLoaded: () => void;
  pageLoadError: () => void;
  urlChangeEvent: (url: string) => void;
  closeEvent: (url: string) => void;
  confirmBtnClicked: (url: string) => void;
  javascriptCallback: (message: string) => void;
  buttonNearDoneClicked: () => void;
}
@Component
export struct WebViewDialog {
  webviewController: web_webview.WebviewController = new web_webview.WebviewController();
  @Prop options: WebViewOptions;
  callbacks: WebViewCallbacks | null = null;
  @State currentUrl: string = "";
  @State canGoBack: boolean = false;
  @State canGoForward: boolean = false;
  @State isHidden: boolean = false;

  private androidInterface: AndroidInterfaceObject = new AndroidInterfaceObject(
    (message: string) => {
      if (this.callbacks) this.callbacks.javascriptCallback(message);
    },
    () => {
      this.handleClose();
    },
    () => {
      this.isHidden = true;
    },
    () => {
      this.isHidden = false;
    },
  );

  aboutToAppear() {
    this.isHidden = this.options.hidden ?? false;
  }

  build() {
    Column() {
      if (this.options.toolbarType !== "blank") {
        this.buildToolbar();
      }
      Web({ src: this.options.url, controller: this.webviewController })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .width("100%")
        .layoutWeight(1)
        .visibility(this.isHidden ? Visibility.Hidden : Visibility.Visible)
        .javaScriptProxy({
          object: this.androidInterface,
          name: "AndroidInterface",
          methodList: ["postMessage", "close", "hide", "show"],
          controller: this.webviewController,
        })
        .onPageBegin((event) => {
          this.currentUrl = event?.url ?? this.currentUrl;
        })
        .onPageEnd((event) => {
          this.currentUrl = event?.url ?? this.currentUrl;
          this.canGoBack = this.webviewController.accessBackward();
          this.canGoForward = this.webviewController.accessForward();
          if (this.callbacks) {
            this.callbacks.pageLoaded();
            this.callbacks.urlChangeEvent(this.currentUrl);
          }
          this.injectPolyfills();
        })
        .onErrorReceive((event) => {
          if (this.callbacks) this.callbacks.pageLoadError();
        })
        .onShowFileSelector((event) => {
          this.handleFileSelector(event as Object);
          return true;
        })
        .onLoadIntercept((event) => {
          let url = event.data.getRequestUrl();
          if (this.options.preventDeeplink && !url.startsWith("http")) {
            return true;
          }
          return false;
        })
    }
    .width("100%")
    .height("100%")
    .backgroundColor(Color.White);
  }

  @Builder
  buildToolbar() {
    Row() {
      Text("✕")
        .fontColor(this.options.toolbarTextColor ?? "#000000")
        .fontSize(24)
        .onClick(() => this.handleClose())
      Blank()
      Text(this.options.title ?? this.getHostname(this.currentUrl))
        .fontColor(this.options.toolbarTextColor ?? "#000000")
        .fontSize(18)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Blank()
      if (this.options.toolbarType === "navigation") {
        Row({ space: 16 }) {
          Text("＜")
            .fontColor(this.canGoBack ? (this.options.toolbarTextColor ?? "#000000") : "#888888")
            .fontSize(24)
            .onClick(() => {
              if (this.canGoBack) this.webviewController.backward();
            })
          Text("＞")
            .fontColor(this.canGoForward ? (this.options.toolbarTextColor ?? "#000000") : "#888888")
            .fontSize(24)
            .onClick(() => {
              if (this.canGoForward) this.webviewController.forward();
            })
          if (this.options.showReloadButton) {
            Text("↻")
              .fontColor(this.options.toolbarTextColor ?? "#000000")
              .fontSize(24)
              .onClick(() => this.webviewController.refresh());
          }
        };
      }
    }
    .width("100%")
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.options.toolbarColor ?? "#FFFFFF");
  }

  private handleClose() {
    if (this.options.closeModal) {
      AlertDialog.show({
        title: this.options.closeModalTitle ?? "Confirm",
        message: this.options.closeModalDescription ?? "Are you sure you want to close?",
        primaryButton: {
          value: this.options.closeModalCancel ?? "Cancel",
          action: () => {},
        },
        secondaryButton: {
          value: this.options.closeModalOk ?? "OK",
          action: () => {
            if (this.callbacks) this.callbacks.confirmBtnClicked(this.currentUrl);
            this.closeDialog();
          },
        },
      });
    } else {
      this.closeDialog();
    }
  }

  private closeDialog() {
    if (this.callbacks) {
      this.callbacks.closeEvent(this.currentUrl);
    }
  }

  private async handleFileSelector(eventObj: Object) {
    let event = eventObj as FileSelectorEvent;
    let fileSelector = event.fileSelector;
    let acceptType = fileSelector.getAcceptType();
    let isCapture = fileSelector.isCapture();
    let eventResult = event.result;

    try {
      if (acceptType.includes("image/*") || isCapture) {
        let photoPicker = new picker.PhotoViewPicker();
        let options = new picker.PhotoSelectOptions();
        options.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
        options.maxSelectNumber = fileSelector.getMode() === 0 ? 1 : 9;

        let result = await photoPicker.select(options);
        if (result && result.photoUris.length > 0) {
          eventResult.handleFileList(result.photoUris);
        } else {
          eventResult.handleFileList([]);
        }
      } else {
        let documentPicker = new picker.DocumentViewPicker();
        let options = new picker.DocumentSelectOptions();
        let result = await documentPicker.select(options);
        if (result && result.length > 0) {
          eventResult.handleFileList(result);
        } else {
          eventResult.handleFileList([]);
        }
      }
    } catch (err) {
      console.error(`InAppBrowser FilePicker Error: ${JSON.stringify(err)}`);
      eventResult.handleFileList([]);
    }
  }

  private injectPolyfills() {
    if (this.options.enableGooglePaySupport) {
      let script = `
        window.open = function(url, target, features) {
            return null; 
        };
      `;
      this.webviewController.runJavaScript(script);
    }
  }

  private getHostname(url: string): string {
    try {
      return Url.URL.parseURL(url).hostname;
    } catch (e) {
      return "";
    }
  }
}

class DialogParams {
  options: WebViewOptions;
  callbacks: WebViewCallbacks;
  constructor(options: WebViewOptions, callbacks: WebViewCallbacks) {
    this.options = options;
    this.callbacks = callbacks;
  }
}

class CustomDialogOptionsImpl {
  isModal: boolean = true;
  alignment: DialogAlignment = DialogAlignment.Center;
}

export class BrowserPlugin extends CapacitorPlugin {
  private dialogNode: ComponentContent<Object> | null = null;
  private uiContext: UIContext | null = null;

  getPluginId(): string {
    return "Browser";
  }

  getMethods(): string[] {
    return ["open", "close", "addListener", "removeAllListeners"];
  }

  async open(call: PluginCall) {
    const url = call.getString("url");
    if (!url) {
      call.reject("Must provide a URL to open");
      return;
    }

    const toolbarColor = call.getString("toolbarColor");
    const presentationStyle = call.getString("presentationStyle"); // popover, fullscreen

    const options = {
      url: url,
      toolbarColor: toolbarColor,
      title: call.getString("windowName"),
    } as WebViewOptions;

    try {
      const win = await window.getLastWindow(this.context);
      this.uiContext = win.getUIContext();

      class CallbacksImpl implements WebViewCallbacks {
        plugin: BrowserPlugin;
        constructor(plugin: BrowserPlugin) {
          this.plugin = plugin;
        }
        pageLoaded() {
          this.plugin.notifyListeners("browserPageLoaded", new Object());
        }
        pageLoadError() {}
        urlChangeEvent(url: string) {}
        closeEvent(url: string) {
          this.plugin.notifyListeners("browserFinished", new Object());
          this.plugin.closeDialog();
        }
        confirmBtnClicked(url: string) {}
        javascriptCallback(message: string) {}
        buttonNearDoneClicked() {}
      }
      let callbacks: WebViewCallbacks = new CallbacksImpl(this);

      this.dialogNode = new ComponentContent(
        this.uiContext,
        wrapBuilder(buildBrowserDialog),
        new DialogParams(options, callbacks),
      );

      this.uiContext.getPromptAction().openCustomDialog(this.dialogNode);

      call.resolve();
    } catch (e) {
      call.reject(typeof e === "string" ? e : e.message);
    }
  }

  async close(call: PluginCall) {
    this.closeDialog();
    call.resolve();
  }

  public closeDialog() {
    if (this.dialogNode && this.uiContext) {
      try {
        this.uiContext.getPromptAction().closeCustomDialog(this.dialogNode);
      } catch (e) {
        hilog.error(0x0000, "BrowserPlugin", "Error closing dialog");
      }
      this.dialogNode = null;
    }
  }
}

@Builder
function buildBrowserDialog(params: Object) {
  WebViewDialog({
    options: (params as DialogParams).options,
    callbacks: (params as DialogParams).callbacks,
  });
}

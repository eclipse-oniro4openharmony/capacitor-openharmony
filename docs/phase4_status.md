# Phase 4: Plugin Runtime MVP - Status: COMPLETE

## Overview
This phase focused on implementing the Plugin Runtime MVP, enabling the execution of native Capacitor plugins within the OpenHarmony environment. Specifically, the `Device` plugin was implemented and verified.

## Achievements
1.  **Plugin Registry**: Implemented `PluginRegistry` to manage and route calls to native plugins dynamically.
2.  **Capacitor Bridge**: Updated `CapacitorBridge` to:
    -   Use `PluginRegistry` for method dispatch.
    -   Handle method invocation dynamically.
    -   Expose the bridge as `androidBridge` directly via `javaScriptProxy` to ensuring compatibility with standard Capacitor web runtime without needing a shim.
    -   Fix ArkTS lint errors (object literals, function calls).
3.  **Device Plugin**: Implemented `DevicePlugin` (extending `CapacitorPlugin`) with:
    -   `getInfo()`: Returns device model, OS version, manufacturer, etc., using OpenHarmony's `deviceInfo` API.
    -   `getId()`: Returns a placeholder UUID (to be implemented fully later).
6.  **App Plugin**: Implemented `App` plugin with:
    -   `exitApp()`: Terminates the application.
    -   Listener support: Added stubs for `addListener`, `removeListener`, and `removeAllListeners` to support event handling (e.g., `appStateChange`, `appUrlOpen`) via the bridge.
7.  **Network Plugin**: Implemented `Network` plugin with:
    -   `getStatus()`: Returns network connection status (WiFi, Cellular, None) using `@ohos.net.connection`.
    -   `networkStatusChange`: Monitors network changes and emits events to the web layer.
8.  **CLI Automation**: Enhanced `sync.ts` to:
    -   Automatically discover installed Capacitor plugins with OpenHarmony support.
    -   Generate `PluginRegistry.ets` dynamically, registering discovered plugins (including `App` and `Network`).
    -   Update `oh-package.json5` to include plugin dependencies.
    -   Fix `oh-package.json5` configuration injection (comma handling, location).
9.  **Dynamic Plugin Headers**:
    -   Implemented `getMethods()` contracts in `CapacitorPlugin` and all core plugins (`Device`, `App`, `Network`).
    -   Updated `sync` command to generate `PluginRegistry.ets` with `getPluginHeaders()` method.
    -   Updated `CapacitorBridge` to inject `PluginHeaders` dynamically avoiding hardcoded values.

## Technical Details
-   **Bridge Communication**:
    -   The bridge uses `window.androidBridge` (injected via `javaScriptProxy`).
    -   **CRITICAL**: A custom JS adapter is injected in `CapacitorBridge.ets` (`injectCapacitorGlobal`) to define `window.Capacitor.nativePromise`, `PluginHeaders`, and callbacks. This is required because `@capacitor/core` 6+ does not include the bridge logic in the JS bundle; it expects the native platform to provide it.
    -   **Dynamic Headers**: `PluginHeaders` are now injected dynamically via `this.registry.getPluginHeaders()`, ensuring that any registered plugin exposes its methods correctly to the web runtime.
-   **Plugin Registry**:
    -   **Automated Generation**: The `sync` command now generates `PluginRegistry.ets` based on `package.json` dependencies.
    -   Core plugins (`Device`, `App`, `Network`) are currently included by default in the generation logic as they reside in the template for this phase.
-   **ArkTS Compatibility**: 
    -   Refactored `CapacitorBridge` to avoid `Function.call` and `Function.apply`.
    -   Used explicit classes (e.g., `EmptyProxy`, `NetworkStatus`) instead of object literals to satisfy ArkTS strict mode.

## Verification
-   The demo app (`ionic-openharmony-demo`) builds and runs on OpenHarmony.
-   The app serves local assets (`index.html`, `js`, `css`) via `http://localhost`.
-   `Device.getInfo()`, `App.exitApp()`, and `Network.getStatus()` are called successfully.
-   Plugin events (`networkStatusChange`) are propagated from native to web.

# Phase 4.1: Debugging Real-World App (Lichobile) - Status: IN PROGRESS

## Overview
This phase focused on debugging and running a real-world Ionic/Capacitor application (`lichobile`, the Lichess mobile app) on OpenHarmony to validate the platform integration and identify missing features.

## Findings & Fixes

### 1. Black Screen Issue (Preferences Plugin)
- **Problem**: The app launched but displayed a black screen. Logs indicated an `Uncaught (in promise) Error: "Preferences" plugin is not implemented on android`.
- **Cause**: The app relies heavily on `@capacitor/preferences` for initialization (session management, settings). The plugin was missing from the OpenHarmony implementation, causing a promise rejection that halted the app's startup sequence.
- **Fix**: 
    - Implemented `Preferences` plugin using `@ohos.data.preferences`.
    - Returns `value: string | null` as expected by Capacitor.
    - Registered the plugin in `PluginRegistry.ets`.
    - **Note**: The error message mentioned "android" likely because the web runtime defaults to assuming "android" when native platform is detected but specific handling is missing, or due to the bridge Shim.

### 2. Device Plugin Enhancement
- **Problem**: Logs showed `Uncaught (in promise) Error: "Device.getLanguageCode()" is not implemented`.
- **Fix**: Implemented `getLanguageCode` in `DevicePlugin` using `@ohos.i18n.getSystemLanguage()`.

### 3. Missing Plugins
The app logs indicate several other missing plugins:
-   `SoundEffect` (custom/community plugin)
-   `PushNotifications` (`@capacitor/push-notifications`)
-   `StatusBar` (`@capacitor/status-bar`)

Despite these missing plugins, the app now proceeds to render the UI and function (game board loads, assets serve, network requests work).

## Technical Implementation (Preferences)
-   Used `@ohos.data.preferences` to persist key-value pairs.
-   Implemented `get`, `set`, `remove`, `clear`, `keys` methods.
-   Handled ArkTS strict mode requirements (explicit classes for return values).

## Verification
-   `lichobile` app launches successfully.
-   Webview renders the game interface.
-   Assets (SVG pieces, fonts, JS bundles) are served correctly via `http://localhost`.
-   Network requests to `lichess.dev` are intercepted and succeed.
-   `WebViewConsole` logs "connected as anonymous" and "all sounds loaded".


## Next Steps 
-   Create a proper JS adapter for OpenHarmony to avoid the `androidBridge` shim.
-   Extract core plugins (`App`, `Device`, `Network`) into separate packages/modules.
-   Implement `FileSystem` plugin.
-   Prepare for initial release/packaging.

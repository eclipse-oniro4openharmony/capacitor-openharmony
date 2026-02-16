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
4.  **Frontend Integration**: Updated `App.tsx` to call `Device.getInfo()` and display the results.
5.  **Native Template**: Synced all native changes to `capacitor-openharmony/assets/native-template`.

## Technical Details
-   **Bridge Communication**:
    -   The bridge uses `window.androidBridge` (injected via `javaScriptProxy`).
    -   **CRITICAL**: A custom JS adapter is injected in `CapacitorBridge.ets` (`injectCapacitorGlobal`) to define `window.Capacitor.nativePromise`, `PluginHeaders`, and callbacks. This is required because `@capacitor/core` 6+ does not include the bridge logic in the JS bundle; it expects the native platform to provide it.
-   **Plugin Registry**:
    -   Disabled automatic generation of `PluginRegistry.ets` in the CLI (`sync.ts`) to allow manual registration for the MVP.
    -   `Device` plugin is manually registered in `PluginRegistry.ets`.
-   **ArkTS Compatibility**: 
    -   Refactored `CapacitorBridge` to avoid `Function.call` and `Function.apply`.
    -   Used explicit classes (e.g., `EmptyProxy`) instead of object literals.

## Verification
-   The demo app (`ionic-openharmony-demo`) builds and runs on OpenHarmony.
-   The app serves local assets (`index.html`, `js`, `css`) via `http://localhost`.
-   `Device.getInfo()` is called, and the native bridge intercepts and routes the call.

## Next Steps (Phase 5)
-   Implement more complex plugins (e.g., `App`, `Network`).
-   Improve the CLI tool to handle plugin installation automatically.
-   Create a proper JS adapter for OpenHarmony to avoid the `androidBridge` shim.

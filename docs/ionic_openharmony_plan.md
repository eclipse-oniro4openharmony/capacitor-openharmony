# Ionic Capacitor OpenHarmony Porting Plan

## 1. Executive Summary
This plan delivers a production-feasible OpenHarmony target for Ionic Capacitor in staged milestones. The immediate goal is a POC with a stable bridge, deterministic asset loading, and one fully functional core plugin. The medium-term goal is a reusable platform adapter package with automated CLI flows and baseline CI coverage.

## 2. Scope, Non-Goals, and Compatibility

### In Scope
1. OpenHarmony platform adapter package published as `@capacitor-community/openharmony`.
2. Native container using ArkUI `Web` with Capacitor bridge semantics.
3. CLI integration for `add`, `sync`, and `open`.
4. MVP plugin runtime with `Device` and plugin registry plumbing.
5. Security hardening for request interception and permission handling.

### Out of Scope (POC)
1. Full parity for all Capacitor community plugins.
2. Advanced background services and multi-ability orchestration.
3. Store publishing pipeline automation.

### Compatibility Matrix (Pinned)
| Component | Baseline |
| :--- | :--- |
| Capacitor | `^6` (pin exact patch in lockfile) |
| Ionic CLI | Latest compatible with selected Capacitor |
| Node.js | `20.x LTS` |
| DevEco Studio | Version pinned in `docs/compatibility.md` |
| OpenHarmony API level | Target level pinned in `build-profile.json5` |
| ohpm/hvigor | Versions pinned in native template and lockfile |

## 3. Repository Strategy

### Repositories to Create
1. `capacitor-openharmony`
2. `ionic-openharmony-demo`

### Repositories to Clone (Reference)
1. `ionic-team/capacitor`
2. OpenHarmony official docs and API samples

## 4. CLI Contract (Unified)
The adapter exposes one command model:
1. `npx cap add openharmony`
2. `npx cap sync openharmony`
3. `npx cap open openharmony`

Rules:
1. `sync` always performs two internal steps in order: `copy` then `update`.
2. Web asset source is always resolved from Capacitor `webDir` (never hardcoded `dist`/`build`/`www` guessing).
3. Config values (`appId`, `appName`, `webDir`) are loaded via Capacitor config APIs and then written into OpenHarmony template files.

## 5. Detailed Implementation Phases

### Phase 1: Foundation and Scaffolding
Goal: establish reproducible local setup and template structure.

Tasks:
1. Create `capacitor-openharmony` package skeleton.
2. Add `native-template` with:
   - `AppScope/app.json5`
   - `hvigorfile.ts`
   - `build-profile.json5`
   - `entry/src/main/ets/{entryability,pages,capacitor}`
3. Create `ionic-openharmony-demo` starter app and lock dependencies.
4. Add `docs/compatibility.md` and pin toolchain versions.

Exit Criteria:
1. `npm ci` succeeds in both repos.
2. Template builds as a blank OpenHarmony app.
3. Compatibility matrix committed and validated.

### Phase 2: Native Runtime Bridge (Manual Prototype)
Goal: verify architecture before automation.

Tasks:
1. Implement `CapacitorBridge.ets`:
   - `getProxyObject().postMessage(json)`
   - strict JSON parsing and error propagation
   - `sendResult(callbackId, data, success)` via `window.Capacitor.fromNative(...)`
2. Implement `Index.ets` with:
   - `.javaScriptAccess(true)`
   - `.domStorageAccess(true)`
   - `.fileAccess(true)`
   - `.javaScriptProxy(...)` exposing `window.HarmonyBridge`
   - `.onInterceptRequest(...)` virtual `https://localhost/*` serving
3. Implement `EntryAbility.ets` lifecycle mapping:
   - `onForeground` -> app active event
   - `onBackground` -> app inactive event
   - `onNewWant` -> deep-link dispatch
   - back-button mapping hook
4. Add path traversal guard and MIME allowlist for intercepted files.

Exit Criteria:
1. `https://localhost/index.html` loads from `rawfile/www`.
2. Bridge roundtrip works for a synthetic call.
3. Lifecycle events (`foreground/background/newWant/back`) are observable in web layer logs.

### Phase 3: CLI Adapter (`@capacitor-community/openharmony`)
Goal: remove manual native edits from developer workflow.

Tasks:
1. Implement `add`:
   - scaffold template into `<project>/openharmony`
   - resolve Capacitor config
   - patch `AppScope/app.json5` and template IDs
2. Implement `sync`:
   - copy assets from resolved `webDir` to `entry/src/main/resources/rawfile/www/`
   - discover installed plugins
   - generate `PluginRegistry.ets`
   - update `oh-package.json5` as needed
3. Implement `open`:
   - open DevEco project on supported host OS (Windows, MacOS)
   - return actionable error on unsupported environments
4. Implement `run`:
   - build and run on supported host OS (Linux, see `run-ohos-app.sh`)

Exit Criteria:
1. `npx cap add openharmony` creates a buildable native project.
2. `npx cap sync openharmony` updates assets and plugin registry deterministically.
3. `npx cap open openharmony` launches project or returns clear fallback instructions.
4. `npx cap run openharmony` builds and runs on supported host OS or returns clear fallback instructions.

### Phase 4: Plugin Runtime MVP
Goal: prove plugin contract end-to-end with maintainable architecture.

Tasks:
1. Introduce base plugin class and registry (`PluginRegistry.ets`) in POC, not hardcoded bridge routing.
2. Implement `Device.getInfo` using OpenHarmony APIs.
3. Add typed plugin call envelope and standardized success/error response serializer.

Exit Criteria:
1. `Device.getInfo()` resolves in demo app with real runtime values.
2. Registry-based dispatch works for at least two plugin methods.

### Phase 5: Security and Permissions
Goal: ensure default-safe runtime behavior.

Tasks:
1. Static permissions workflow:
   - plugin-declared permission metadata
   - `sync` report listing missing manifest entries
2. Runtime permissions helper:
   - check/grant flows
   - standardized `PermissionDenied` errors
3. Request interception hardening:
   - canonicalize and validate paths
   - deny `..` traversal
   - explicit MIME mapping
   - cache headers policy for JS/CSS

Exit Criteria:
1. Permissions are validated pre-build.
2. Denied permission paths return deterministic JS errors.
3. Security checks block malformed URL path requests.

### Phase 6: Verification, Testing, and CI
Goal: move from manual demo to repeatable quality gates.

Test Layers:
1. Unit tests:
   - message parser
   - serializer
   - path sanitizer
2. Integration tests:
   - `sync` copy/update behavior
   - plugin discovery and registry generation
3. Device/emulator smoke:
   - app boot
   - bridge call
   - `Device.getInfo`
4. CI pipeline:
   - lint + typecheck + unit tests on PR
   - integration tests on adapter package

Exit Criteria:
1. CI required checks pass on every PR.
2. POC demo passes smoke test script on at least one emulator/device target.

## 6. Phase Gates and Validation Commands
| Phase | Deliverable | Validation Command | Pass Condition |
| :--- | :--- | :--- | :--- |
| 1 | Scaffolded repos + template | `npm ci` | Clean install and build metadata present |
| 2 | Manual bridge prototype | Run demo in DevEco | UI loads + bridge roundtrip logs |
| 3 | CLI adapter | `npx cap add/sync/open openharmony` | Commands produce deterministic output |
| 4 | Plugin MVP | Demo `Device.getInfo()` | Real payload rendered in app |
| 5 | Security/permissions hardening | Security smoke checks | Traversal blocked + permission errors normalized |
| 6 | CI quality gate | CI workflow run | Required checks green |

## 7. Risk Register
| Risk | Impact | Mitigation | Owner |
| :--- | :--- | :--- | :--- |
| ArkWeb/ArkTS bridge timing issues | High | Queue bridge calls until web runtime ready | Runtime |
| `onInterceptRequest` path bugs | High | Canonicalization + denylist/allowlist tests | Runtime |
| Toolchain drift (DevEco/hvigor/ohpm) | Medium | Pin versions + compatibility doc + scheduled refresh | Build |
| Plugin parity expectations | High | Publish explicit support matrix and fallback behavior | Plugin |
| Manual-only verification | Medium | CI smoke automation and scripted checks | QA/Infra |

## 8. Milestone Roadmap
1. M1 (Weeks 1-2): Phase 1 complete.
2. M2 (Weeks 3-5): Phase 2 complete with manual prototype.
3. M3 (Weeks 6-8): Phase 3 complete with CLI adapter (`add`, `sync`, `run`).
4. M4 (Weeks 9-10): Phase 4 complete with registry-based Device plugin.
5. M5 (Weeks 11-12): Phases 5-6 complete with baseline CI.

## 9. Required Resources (Primary Sources)
1. Capacitor repository and platform internals:
   - https://github.com/ionic-team/capacitor
2. OpenHarmony UIAbility lifecycle docs:
   - https://gitee.com/openharmony/docs/blob/master/en/application-dev/application-models/uiability-lifecycle.md
3. ArkUI Web component and web events docs:
   - https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-basic-components-web-0000001813553488
   - https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-basic-components-web-events

## 10. Immediate Next Execution Items
1. Implement Phase 1 repository scaffolding and version pinning.
2. Build Phase 2 bridge prototype with secure `onInterceptRequest`.
3. Add CLI `sync` using `webDir` resolution and generated `PluginRegistry.ets`.

# Capacitor OpenHarmony

This project provides an OpenHarmony platform adapter for [Ionic Capacitor](https://capacitorjs.com/), allowing developers to run Ionic and web applications on OpenHarmony devices and emulators.

## Overview

Capacitor OpenHarmony brings the cross-platform power of Capacitor to the OpenHarmony ecosystem. It provides a native container using the ArkUI `Web` component and a bridge that implements Capacitor's plugin semantics, enabling seamless communication between web code and native OpenHarmony APIs.

## Project Structure

- `capacitor-openharmony/`: The core platform adapter package (`@capacitor-community/openharmony`).
- `plugins/`: OpenHarmony-specific implementations of Capacitor core plugins (e.g., Device, Filesystem, Preferences).
- `ionic-openharmony-demo/`: A sample Ionic React application configured for OpenHarmony.
- `docs/`: Technical plans, status reports, and architecture documentation.

## Running an Ionic App on OpenHarmony

To run an Ionic application using this plugin, follow these steps (illustrated using the provided demo app):

### 1. Prerequisites

- **DevEco Studio**: Install the latest version of [DevEco Studio](https://developer.huawei.com/consumer/en/deveco-studio/).
- **OpenHarmony SDK**: Ensure you have the OpenHarmony SDK configured in DevEco Studio.
- **Node.js**: Version 20.x or later.

### 2. Setup and Build

Navigate to your Ionic project (e.g., `ionic-openharmony-demo`) and install dependencies:

```bash
cd ionic-openharmony-demo
npm install
```

Build your web project:

```bash
npm run build
```

### 3. Add OpenHarmony Platform

If you haven't already, add the OpenHarmony platform to your Capacitor project:

```bash
npx cap add openharmony
```

### 4. Sync Assets and Plugins

Sync your web assets and Capacitor plugins to the native OpenHarmony project:

```bash
npx cap sync openharmony
```

### 5. Configure Signing

OpenHarmony applications require a signature to run on physical devices and some emulators.

1.  Open the `openharmony` folder within your project in **DevEco Studio**.
2.  Navigate to **File > Project Structure > Project > Signing Configs**.
3.  Click **Automatically generate signature** (requires a login with a Huawei ID).

### 6. Run the Application

You can run the application directly from DevEco Studio or use the provided helper script if you have a device connected via `hdc`:

```bash
./run-ohos-app.sh
```

## CLI Commands

The Capacitor CLI is extended with OpenHarmony support:

- `npx cap add openharmony`: Initialize the native OpenHarmony project.
- `npx cap sync openharmony`: Copy web assets and sync plugin dependencies.
- `npx cap open openharmony`: Launch the project in DevEco Studio.

## Documentation

For more detailed information, please refer to the [docs](./docs) directory:
- [Porting Plan](./docs/ionic_openharmony_plan.md)
- [Phase Status Reports](./docs/phase4_status.md)

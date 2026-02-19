# Ionic OpenHarmony Demo

This project demonstrates how to run an Ionic/Capacitor application on OpenHarmony.

## Build and Run

Follow these steps to build and run the project:

1.  **Install dependencies:**
    ```bash
    npm install
    ```

2.  **Build the web assets:**
    ```bash
    npm run build
    ```

3.  **Add the OpenHarmony platform:**
    ```bash
    npx cap add openharmony
    ```

4.  **Sync the project:**
    ```bash
    npx cap sync openharmony
    ```

5.  **Generate Signature Configs:**
    You must manually generate signature configs in the `openharmony` target code. This can be done using:
    *   **DevEco Studio**: Open the `openharmony` folder in DevEco Studio and configure the signing configs in the Project Structure.
    *   **Oniro Builder Scripts**: If you have the onirobuilder tool installed, you can run `onirobuilder sign` to generate the signature configs.

6.  **Run the application:**
    Use the provided helper script to build the HAP and install it on a connected device:
    ```bash
    ./run-ohos-app.sh --grep string_to_filter_logs
    ```

Android
=======

## Disable MIUI12 charging sound

1. Enable developer options;
2. Enable USB debugging and USB debugging (Security settings);
3. Change settings using `adb`

    ```sh
    sudo ./adb start-server
    sudo ./adb shell settings put global power_sounds_enabled 0
    ```


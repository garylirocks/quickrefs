Ionic
===============

## detect current platform

test whether running in a device or browser

    if (window.cordova) {
      // running on device/emulator
    } else {
      // running in dev mode
    }

or

    ionic.Platform.platforms
    ["browser", "linux"]

or 

    ionic.Platform.isIOS()
    ionic.Platform.isAndroid()
    ionic.Platform.isEdge()
    ionic.Platform.isCrosswalk()
    ionic.Platform.isIPad()
    ionic.Platform.isWebView()
    ionic.Platform.isWindowsPhone()



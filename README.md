# cordova-plugin-admob-jd
A Cordova AdMob plugin used for Android and iOS. It is free, with no ad sharing or remote code. It gets updated as needed to support the apps I develop and maintain. There may be other plugins with more features, but I can depend on this code to fullful my needs and not crash my code. 

# Quick Start

To install this plugin, follow the [Command-line Interface Guide](http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-line%20Interface).

```
cordova plugin add cordova-plugin-admob-jd --variable APP_ID_ANDROID="<YOUR_ANDROID_ADMOB_APP_ID>" --variable APP_ID_IOS="<YOUR_IOS_ADMOB_APP_ID>"

```
* Note: If you add the correct ADMOB_APP_ID after the build you may need to remove the plugin and re-add it as the original value is saved in the plugin folder and overrides the config settings.
# FAQ
How to fix 'GoogleMobileAds/GoogleMobileAds.h' file not found error?#
This is likely caused by CocoaPods is not installing the dependencies correctly.

Run pod repo update and cd platforms/ios && pod install --repo-update to ensure latest SDK is ready.

A clean build / remove then re-add the plugin may be necessary.

# Change Log
## 1.1.3
- Added SKAdNetworkItems for iOS
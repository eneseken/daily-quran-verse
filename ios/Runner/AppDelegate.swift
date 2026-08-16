import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let appIconChannelName = "com.muslim.pro/app_icon"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: appIconChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "setIcon" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard UIApplication.shared.supportsAlternateIcons else {
          result(FlutterError(
            code: "UNSUPPORTED",
            message: "Alternate app icons are not supported on this device.",
            details: nil
          ))
          return
        }
        let arguments = call.arguments as? [String: Any]
        let id = arguments?["id"] as? String
        let iconName = id.flatMap { "AppIconAlt\($0)" }
        UIApplication.shared.setAlternateIconName(iconName) { error in
          if let error = error {
            result(FlutterError(
              code: "APP_ICON_ERROR",
              message: error.localizedDescription,
              details: nil
            ))
          } else {
            result(nil)
          }
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

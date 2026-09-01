import Flutter
import UIKit
import CallKit
import Contacts

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let CHANNEL = "com.sysadmindoc.callshield/platform"
  private let EXTENSION_IDENTIFIER = "com.sysadmindoc.callshield.CallDirectoryExtension"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

    methodChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let self = self else { return }

      switch call.method {
      case "isCallScreeningSupported":
        result(true)

      case "isCallScreeningEnabled":
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: self.EXTENSION_IDENTIFIER) { (status, error) in
          DispatchQueue.main.async {
            if let error = error {
              result(false)
            } else {
              result(status == .enabled)
            }
          }
        }

      case "requestCallScreeningRole":
        // iOS requires user to enable Call Blocking & Identification in Phone settings
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
          if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { success in
              result(success)
            })
          } else {
            result(false)
          }
        } else {
          result(false)
        }

      case "reloadCallDirectory":
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: self.EXTENSION_IDENTIFIER) { (error) in
          DispatchQueue.main.async {
            if let error = error {
              result(false)
            } else {
              result(true)
            }
          }
        }

      case "getContactsPermissionStatus":
        let status = CNContactStore.authorizationStatus(for: .contacts)
        result(status == .authorized)

      case "requestContactsPermission":
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
          DispatchQueue.main.async {
            result(granted)
          }
        }

      case "openAppSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url, options: [:], completionHandler: { success in
            result(success)
          })
        } else {
          result(false)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

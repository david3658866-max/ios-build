import Flutter
import UIKit
import Security
import DeviceCheck

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: "com.cyberis.vortek/device_info",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "readOrCreateIosHardwareId":
        result(IosHardwareIdStore.readOrCreate())
      case "generateDeviceCheckToken":
        IosDeviceCheckToken.generate(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

enum IosDeviceCheckToken {
  static func generate(result: @escaping FlutterResult) {
    guard DCDevice.current.isSupported else {
      result(nil)
      return
    }
    DCDevice.current.generateToken { data, error in
      if error != nil {
        result(nil)
        return
      }
      guard let data = data else {
        result(nil)
        return
      }
      result(data.base64EncodedString())
    }
  }
}

/// Keychain-backed hardware id: survives typical app reinstall; factory reset still clears it.
enum IosHardwareIdStore {
  private static let service = "com.cyberis.vortek.device"
  private static let account = "hardware_id"

  static func readOrCreate() -> String {
    if let existing = read(), !existing.isEmpty {
      return existing
    }
    let fresh = UIDevice.current.identifierForVendor?.uuidString
      ?? UUID().uuidString
    _ = save(fresh)
    return fresh
  }

  private static func read() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  @discardableResult
  private static func save(_ value: String) -> Bool {
    guard let data = value.data(using: .utf8) else { return false }
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(query as CFDictionary)
    var add = query
    add[kSecValueData as String] = data
    add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
  }
}

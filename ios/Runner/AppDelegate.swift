import Flutter
import UIKit
import LocalAuthentication
import Security

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.brightbank.app/biometrics",
                                        binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler({
        [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        self?.handle(call, result: result)
      })
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BiometricSignaturePlugin")
    let channel = FlutterMethodChannel(name: "com.brightbank.app/biometrics",
                                      binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      self?.handle(call, result: result)
    })
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      isAvailable(result: result)
    case "createKeyPair":
      guard let args = call.arguments as? [String: Any],
            let alias = args["alias"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Alias is missing", details: nil))
        return
      }
      createKeyPair(alias: alias, result: result)
    case "sign":
      guard let args = call.arguments as? [String: Any],
            let alias = args["alias"] as? String,
            let data = args["data"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Alias or Data is missing", details: nil))
        return
      }
      let subtitle = args["subtitle"] as? String ?? "Authenticate to sign your login request"
      signData(alias: alias, dataToSignBase64: data, subtitle: subtitle, result: result)
    case "authenticate":
      let args = call.arguments as? [String: Any]
      let subtitle = args?["subtitle"] as? String ?? "Verify your identity to continue"
      authenticate(subtitle: subtitle, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isAvailable(result: @escaping FlutterResult) {
    let context = LAContext()
    var error: NSError?
    let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    result(["isAvailable": available])
  }

  private func createKeyPair(alias: String, result: @escaping FlutterResult) {
    let aliasData = alias.data(using: .utf8)!

    // Delete any existing key with the same alias first
    let deleteQuery: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: aliasData,
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA
    ]
    SecItemDelete(deleteQuery as CFDictionary)

    var error: Unmanaged<CFError>?

    // Create access control demanding biometry (FaceID / TouchID)
    guard let accessControl = SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        .biometryAny,
        &error
    ) else {
        result(FlutterError(code: "KEY_CONTROL_ERROR", message: "Failed to create access control: \(error?.takeRetainedValue().localizedDescription ?? "Unknown error")", details: nil))
        return
    }

    let privateKeyAttr: [String: Any] = [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: aliasData,
        kSecAttrAccessControl as String: accessControl
    ]

    let parameters: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits as String: 2048,
        kSecPrivateKeyAttrs as String: privateKeyAttr
    ]

    guard let privateKey = SecKeyCreateRandomKey(parameters as CFDictionary, &error) else {
        result(FlutterError(code: "KEY_GENERATION_ERROR", message: "Failed to generate private key: \(error?.takeRetainedValue().localizedDescription ?? "Unknown error")", details: nil))
        return
    }

    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
        result(FlutterError(code: "KEY_COPY_ERROR", message: "Failed to copy public key", details: nil))
        return
    }

    var pubKeyError: Unmanaged<CFError>?
    guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &pubKeyError) as Data? else {
        result(FlutterError(code: "KEY_REPRESENTATION_ERROR", message: "Failed to copy public key data: \(pubKeyError?.takeRetainedValue().localizedDescription ?? "Unknown error")", details: nil))
        return
    }

    // Wrap raw PKCS#1 RSA Public Key in X.509/PKCS#8 SubjectPublicKeyInfo PEM format to match Android output exactly
    let base64PublicKey: String
    if publicKeyData.count == 270 {
        let rsa2048Header = Data([
            0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
            0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
        ])
        var pkcs8Data = Data()
        pkcs8Data.append(rsa2048Header)
        pkcs8Data.append(publicKeyData)
        base64PublicKey = pkcs8Data.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
    } else {
        base64PublicKey = publicKeyData.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
    }
    let pemString = "-----BEGIN PUBLIC KEY-----\n\(base64PublicKey)\n-----END PUBLIC KEY-----"

    result(["publicKey": pemString])
  }

  private func signData(alias: String, dataToSignBase64: String, subtitle: String, result: @escaping FlutterResult) {
    let aliasData = alias.data(using: .utf8)!

    // Initialize LocalAuthentication context to customize biometric prompt messages
    let context = LAContext()
    context.localizedReason = subtitle

    let query: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: aliasData,
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecReturnRef as String: true,
        kSecUseAuthenticationContext as String: context
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status != errSecSuccess {
        result(FlutterError(code: "KEY_NOT_FOUND", message: "Key not found. Please setup biometrics first. (status: \(status))", details: nil))
        return
    }

    let privateKey = item as! SecKey

    guard let dataToSign = Data(base64Encoded: dataToSignBase64) else {
        result(FlutterError(code: "INVALID_BASE64", message: "Invalid base64 data to sign", details: nil))
        return
    }

    var error: Unmanaged<CFError>?
    // Perform SHA-256 with RSA PKCS1 v1.5 signature (matching OPENSSL_ALGO_SHA256 / SHA256withRSA)
    guard let signatureData = SecKeyCreateSignature(
        privateKey,
        .rsaSignatureMessagePKCS1v15SHA256,
        dataToSign as CFData,
        &error
    ) as Data? else {
        result(FlutterError(code: "SIGNING_FAILED", message: "Failed to sign data: \(error?.takeRetainedValue().localizedDescription ?? "Unknown error")", details: nil))
        return
    }

    let signatureBase64 = signatureData.base64EncodedString()
    result(["signature": signatureBase64])
  }

  private func authenticate(subtitle: String, result: @escaping FlutterResult) {
    let context = LAContext()
    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: subtitle) { success, error in
        DispatchQueue.main.async {
            if success {
                result(["verified": true])
            } else {
                result(FlutterError(code: "AUTH_ERROR", message: "Authentication failed: \(error?.localizedDescription ?? "Unknown error")", details: nil))
            }
        }
    }
  }
}

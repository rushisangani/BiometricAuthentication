# ``BiometricAuthentication``

Authenticate users with Face ID, Touch ID, Optic ID or the device passcode.

## Overview

Create a ``BiometricAuthenticator`` and call one of its authentication functions. Failures are reported as ``AuthenticationError``, with localized messages looked up in your own bundle and strings table.

```swift
var authenticator = BiometricAuthenticator(bundle: .main, tableName: "Localizable")
authenticator.allowableReuseDuration = 30

do {
    try await authenticator.authenticateWithBiometrics(reason: "")
} catch let error as AuthenticationError {
    print(error.message(using: authenticator))
} catch {
    print(error.localizedDescription)
}
```

Add `NSFaceIDUsageDescription` to your app's Info.plist to use Face ID.

## Topics

### Creating an authenticator

- ``BiometricAuthenticator``
- ``BiometricAuthenticator/init(bundle:tableName:)``
- ``BiometricAuthenticator/allowableReuseDuration``

### Authenticating

- ``BiometricAuthenticator/authenticateWithBiometrics(reason:fallbackTitle:cancelTitle:)``
- ``BiometricAuthenticator/authenticateWithPasscode(reason:cancelTitle:)``
- ``BiometricAuthenticator/authenticateWithBiometrics(reason:fallbackTitle:cancelTitle:completion:)``
- ``BiometricAuthenticator/authenticateWithPasscode(reason:cancelTitle:completion:)``

### Checking availability

- ``BiometricAuthenticator/canAuthenticate()``
- ``BiometricAuthenticator/faceIDAvailable()``
- ``BiometricAuthenticator/touchIDAvailable()``
- ``BiometricAuthenticator/opticIDAvailable()``
- ``BiometricAuthenticator/isFaceIDDevice()``
- ``BiometricAuthenticator/isOpticIDDevice()``

### Handling errors

- ``AuthenticationError``
- ``AuthenticationError/init(_:)``
- ``AuthenticationError/message(using:)``

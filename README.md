# BiometricAuthentication
Use Apple Face ID, Touch ID or Optic ID authentication in your app using BiometricAuthentication.
It's very simple and easy to use that handles biometric and device passcode authentication based on the device.

**Note:** - Face ID authentication requires user's permission to be added in Info.plist.
```xml
<key>NSFaceIDUsageDescription</key>
<string>This app requires Face ID permission to authenticate using Face recognition.</string>
```

## What's new in version 4.1.0
- **One prompt at a time** - Starting a new authentication invalidates the one still in progress on the same authenticator, which fails with `canceledByApp`. Repeated calls (for ex. each time the app becomes active) no longer leave stale prompts behind.
- **Main actor class** - `BiometricAuthenticator` is now a `@MainActor final class`. Availability checks such as `faceIDAvailable()` can still be called from any thread.
- **Face ID permission message** - When the user denies the app's Face ID permission, `biometryNotAvailable` shows a Face ID message pointing to Settings (`faceid.not.available`).

## What's new in version 4.0.0
- **async/await support** - `authenticateWithBiometrics` and `authenticateWithPasscode` are now `async throws` and simply return on success. Completion-handler variants are still available, are called on the main actor and receive `Result<Void, AuthenticationError>`.
- **Swiftier names** - `authenticateWithBioMetrics` is now `authenticateWithBiometrics`, `isFaceIdDevice()` is now `isFaceIDDevice()`, and `AuthenticationError.initWithError(_:)` is now `AuthenticationError(_:)`.
- **No singleton** - Create and keep your own `BiometricAuthenticator` instead of using `BioMetricAuthenticator.shared`.
- **Localized strings** - All messages are looked up in your own bundle and strings table (`.strings` or `.xcstrings`), with built-in English defaults for any missing key.
- **More error cases** - `AuthenticationError` now covers `canceledByApp`, `invalidContext`, `notInteractive` and `companionNotAvailable`, matching Apple's `LAError`.
- **Optic ID** support for Apple Vision Pro.
- `AuthenticationError` conforms to `LocalizedError`, so `error.localizedDescription` returns a readable message.
- Swift Package Manager support with a privacy manifest (`PrivacyInfo.xcprivacy`), DocC documentation and unit tests written with Swift Testing.
- Minimum deployment target is now **iOS 15.0**.

See [Migrating from 3.x](#migrating-from-3x) for API changes.

![Alt text](https://raw.githubusercontent.com/rushisangani/BiometricAuthentication/master/Images/image1.png "Authenticate")
![Alt text](https://raw.githubusercontent.com/rushisangani/BiometricAuthentication/master/Images/image2.png "Fallback title")
![Alt text](https://raw.githubusercontent.com/rushisangani/BiometricAuthentication/master/Images/image3.png "Locked out")

## Features

- Works with Face ID, Touch ID and Optic ID, picking the right behavior and messages for the device.
- Swift Concurrency (async/await) and completion-handler APIs.
- Predefined, localizable error messages when recognition fails.
- Device passcode authentication to unlock biometry after multiple failed attempts.
- Reuse a recent Face ID or Touch ID lock-screen unlock without prompting again (`allowableReuseDuration`).

## Requirements

- iOS 15.0+
- Xcode 15+ (Swift 5.9+). Works in both Swift 5 and Swift 6 language modes.
- Xcode 16+ to run the package's unit tests (Swift Testing).

## Installation

### Swift Package Manager

In Xcode choose **File → Add Package Dependencies…** and enter the repository URL, or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rushisangani/BiometricAuthentication.git", from: "4.1.0")
]
```

### CocoaPods

```ruby
pod 'BiometricAuthentication', '~> 4.0'
```

## Usage

### Create an authenticator

```swift
import BiometricAuthentication

// Localized messages are looked up in the given bundle and strings table (defaults: `.main`, "Localizable").
let authenticator = BiometricAuthenticator(bundle: .main, tableName: "Localizable")

// Optional: reuse a recent lock-screen unlock (in seconds) without prompting again. Default is 0 (no reuse).
authenticator.allowableReuseDuration = 30
```
- Keep the authenticator as a property (for ex. in your view controller or view model) and reuse it. It is a `@MainActor` class, so authenticate from the main actor or `await` the call.
- Only one authentication runs at a time per authenticator: starting a new one invalidates the one still in progress, which fails with `AuthenticationError.canceledByApp`.

### Allowable Reuse Duration
- If the user unlocked the device with Face ID or Touch ID on the **lock screen** within `allowableReuseDuration` seconds, `authenticateWithBiometrics` succeeds immediately without showing a prompt.
- Only lock-screen unlocks are reused. A previous biometric authentication inside your app (or another app) is never reused, so calling `authenticateWithBiometrics` twice in a row prompts twice.
- The maximum is 5 minutes (`LATouchIDAuthenticationMaximumAllowableReuseDuration`); larger values are clamped. It does not apply to `authenticateWithPasscode`.
- This can only be verified on a real device: lock the device, unlock it with Face ID or Touch ID, open the app and authenticate within the duration. The simulator can't simulate a lock-screen biometric unlock.

### Authenticate with biometric

```swift
do {
    try await authenticator.authenticateWithBiometrics(reason: "")
    print("Authentication Successful")
} catch let error as AuthenticationError {
    print(error.message(using: authenticator))
} catch {
    print("Authentication Failed")
}
```
- When reason specified as empty - default will be used based on the device. Ex. for Face ID devices - **"Confirm your face to authenticate."**,  For Touch ID devices - **"Confirm your fingerprint to authenticate."**
- The functions only throw `AuthenticationError`, but because Swift 5 throws are untyped a final `catch` is still required.
- From UIKit, call it inside a `Task`:

```swift
@IBAction func biometricAuthenticationClicked(_ sender: Any) {
    Task {
        do {
            try await authenticator.authenticateWithBiometrics(reason: "")
        } catch {
            // handle error
        }
    }
}
```

### Completion handler

- Completion-handler variants are available for both biometric and passcode authentication. The completion is called on the main actor.

```swift
authenticator.authenticateWithBiometrics(reason: "") { result in
    switch result {
    case .success:
        print("Authentication Successful")
    case .failure(let error):
        print(error.message(using: authenticator))
    }
}
```

### Can Authenticate with biometric

- Alternatively you can check before authentication by following. This will check that if device supports Touch ID, Face ID or Optic ID authentication and your app can use that as of now.

```swift
if BiometricAuthenticator.canAuthenticate() {
    try await authenticator.authenticateWithBiometrics(reason: "")
}
```
### Check for Face ID, Touch ID or Optic ID
- Check if the device supports the biometry type and it is available (enrolled and not locked) right now.
```swift
if authenticator.faceIDAvailable() {
    // device supports face id recognition.
}
if authenticator.touchIDAvailable() {
    // device supports touch id authentication
}
if authenticator.opticIDAvailable() {
    // device supports optic id authentication (Apple Vision Pro)
}
```
- Check only the hardware, regardless of enrollment or availability.
```swift
authenticator.isFaceIDDevice()
authenticator.isOpticIDDevice()
```

### Fallback and Cancel Title
- The fallback button is shown by the system after a failed attempt; iOS decides exactly when (Face ID may offer "Try Face ID Again" first).
- You can give alternate authentication options like enter 'username & password' when user clicks on fallback button.
- Default fallback title is empty, which will hide fallback button. Pass `nil` to show the system default title.
- Use `cancelTitle` to customize the cancel button title.

```swift
do {
    try await authenticator.authenticateWithBiometrics(reason: "Biometric Authentication", fallbackTitle: "Enter Credentials", cancelTitle: "Not Now")
    // proceed further
} catch AuthenticationError.fallback {
    // show alternatives on fallback button clicked
    // for ex. - enter username/email and password
} catch {
    print("Authentication Failed")
}
```

### BiometryLockedout
- When biometry authentication is locked out after multiple failed attempts. You can unlock it by passcode authentication.
- Provide your own passcode authentication reason here, default will be used if empty.

```swift
do {
    try await authenticator.authenticateWithPasscode(reason: message)
    // passcode authentication success
} catch let error as AuthenticationError {
    print(error.message(using: authenticator))
} catch {
    print("Authentication Failed")
}
```

### Localization
- The SDK does not ship translations. Add these keys to the strings table passed to `BiometricAuthenticator(bundle:tableName:)` (`Localizable` in the main bundle by default) to customize or translate the messages. English defaults are used for any missing key.
- `error.message(using: authenticator)` returns the localized message for an error, using that authenticator's bundle and table. `error.localizedDescription` uses the main bundle and `Localizable` table.

| Key | Default (English) |
|---|---|
| `biometry.not.available` | Biometric authentication is not available for this device. |
| `companion.not.available` | No paired companion device is nearby. Please bring your Apple Watch closer and try again. |
| `touchid.authentication.reason` | Confirm your fingerprint to authenticate. |
| `touchid.passcode.authentication.reason` | Touch ID is locked now, because of too many failed attempts. Enter passcode to unlock Touch ID. |
| `touchid.set.passcode` | Please set device passcode to use Touch ID for authentication. |
| `touchid.not.enrolled` | There are no fingerprints enrolled in the device. Please go to Device Settings -> Touch ID & Passcode and enroll your fingerprints. |
| `touchid.failed.reason` | Touch ID does not recognize your fingerprint. Please try again with your enrolled fingerprint. |
| `faceid.authentication.reason` | Confirm your face to authenticate. |
| `faceid.passcode.authentication.reason` | Face ID is locked now, because of too many failed attempts. Enter passcode to unlock Face ID. |
| `faceid.set.passcode` | Please set device passcode to use Face ID for authentication. |
| `faceid.not.available` | Face ID is not available. Please allow this app to use Face ID in Settings. |
| `faceid.not.enrolled` | There is no face enrolled in the device. Please go to Device Settings -> Face ID & Passcode and enroll your face. |
| `faceid.failed.reason` | Face ID does not recognize your face. Please try again with your enrolled face. |
| `opticid.authentication.reason` | Confirm your eyes to authenticate. |
| `opticid.passcode.authentication.reason` | Optic ID is locked now, because of too many failed attempts. Enter passcode to unlock Optic ID. |
| `opticid.set.passcode` | Please set device passcode to use Optic ID for authentication. |
| `opticid.not.enrolled` | There are no eyes enrolled in the device. Please go to Device Settings -> Optic ID & Passcode and enroll your eyes. |
| `opticid.failed.reason` | Optic ID does not recognize your eyes. Please try again with your enrolled eyes. |

- See [Localizable.xcstrings](Example/Shared/Localizable.xcstrings) in the example apps for a ready-to-copy string catalog.

### Error Handling
- There are various cases when biometric authentication can be failed. Each case maps to Apple's `LAError`.

1. **fallback**
    - Called when user clicks on provided fallback button.
2. **biometryNotEnrolled**
    - Called when no fingerprints, face or eyes are registered with the device.
    - You can show message to register a new face or fingerprint here.
3. **canceledByUser**
    - Called when authentication canceled by user.
4. **canceledBySystem**
    - Called when authentication canceled by system when app goes into background or any other reason.
5. **canceledByApp**
    - Called when authentication canceled by the app invalidating the context.
6. **passcodeNotSet**
    - Called when device passcode is not set and trying to use biometry authentication.
    - We can ask user to set device passcode here by opening Settings Application.
7. **failed**
    - Called when user failed to provide valid credentials.
    - You can show error message to user here.
8. **biometryLockedout**
    - Called when biometry is locked because there were too many failed attempts.
    - You'll restrict user when this error is occurred.
    - Alternatively you can ask user to enter device passcode to unlock biometry.
9. **biometryNotAvailable**
    - Called when device does not support Face ID, Touch ID or Optic ID authentication.
10. **invalidContext**
    - Called when the context was previously invalidated.
11. **notInteractive**
    - Called when displaying the required authentication UI is forbidden.
12. **companionNotAvailable**
    - Called when no paired companion device (e.g. Apple Watch) is nearby.
13. **other**
    - Called for any other, unmapped error.

- `message(using:)` returns an empty string for `canceledByUser`, `canceledBySystem`, `canceledByApp` and `fallback`, as no message should be shown for these.

### Example

```swift
do {
    try await authenticator.authenticateWithBiometrics(reason: "")

    // authentication successful
    showLoginSuccessAlert()

} catch let error as AuthenticationError {
    let message = error.message(using: authenticator)

    switch error {

    // device does not support biometric (face id or touch id) authentication
    case .biometryNotAvailable:
        showErrorAlert(message: message)

    // No biometry enrolled or passcode not set in this device, ask user to update settings
    case .biometryNotEnrolled, .passcodeNotSet:
        showGoToSettingsAlert(message: message)

    // show alternatives on fallback button clicked
    case .fallback:
        txtUsername.becomeFirstResponder() // enter username password manually

    // Biometry is locked out now, because there were too many failed attempts.
    // Need to enter device passcode to unlock.
    case .biometryLockedout:
        showPasscodeAuthentication(message: message)

    // do nothing on canceled by system, user or app
    case .canceledBySystem, .canceledByUser, .canceledByApp:
        break

    // show error for any other reason
    default:
        showErrorAlert(message: message)
    }
} catch {
    showErrorAlert(message: error.localizedDescription)
}
```
See [Example](https://github.com/rushisangani/BiometricAuthentication/tree/master/Example) for more details.

## Migrating from 3.x

| 3.x | 4.0.0 |
|---|---|
| `BioMetricAuthenticator.shared.allowableReuseDuration = 60` | `var authenticator = BiometricAuthenticator()`<br>`authenticator.allowableReuseDuration = 60` |
| `BioMetricAuthenticator.authenticateWithBioMetrics(reason:) { result in }` | `try await authenticator.authenticateWithBiometrics(reason:)`<br>or `authenticator.authenticateWithBiometrics(reason:) { result in }` |
| `case .success(let success):` (`Result<Bool, AuthenticationError>`) | `case .success:` (`Result<Void, AuthenticationError>`) |
| `BioMetricAuthenticator.authenticateWithPasscode(reason:) { result in }` | `try await authenticator.authenticateWithPasscode(reason:)`<br>or `authenticator.authenticateWithPasscode(reason:) { result in }` |
| `BioMetricAuthenticator.shared.faceIDAvailable()` | `authenticator.faceIDAvailable()` |
| `BioMetricAuthenticator.canAuthenticate()` | `BiometricAuthenticator.canAuthenticate()` |
| `error.message()` | `error.message(using: authenticator)` (`error.message()` still uses the main bundle) |
| `AuthenticationError.initWithError(laError)` | `AuthenticationError(laError)` |
| `BioMetricAuthenticator.shared.isFaceIdDevice()` | `authenticator.isFaceIDDevice()` |

- `BioMetricAuthenticator` is renamed to `BiometricAuthenticator`. The old name is still available as a deprecated typealias.
- `authenticateWithBioMetrics` is renamed to `authenticateWithBiometrics` (lowercase **m**).
- Authentication no longer returns a `Bool`: the async functions return on success and throw an `AuthenticationError` on failure, and completion handlers receive `Result<Void, AuthenticationError>`.
- Completion handlers are now called on the main actor and must be `@Sendable`; closures written inline need no changes.
- `BiometricAuthenticator` is a `@MainActor final class`: call authentication from the main actor (for ex. a view controller or `@MainActor` view model) or `await` it.
- The `shared` singleton is removed.
- New `AuthenticationError` cases were added. Add a `default` case to any exhaustive `switch` over the error.
- Minimum deployment target is now iOS 15.0.
- Carthage is no longer supported. Use Swift Package Manager or CocoaPods.

## Development

```
Sources/BiometricAuthentication/          Library sources, privacy manifest and DocC catalog
Tests/BiometricAuthenticationTests/       Unit tests (Swift Testing)
Example/                                  Example apps (separate Xcode project, depends on the local package)
├── UIKit/                                UIKit + storyboard example
├── SwiftUI/                              SwiftUI example
└── Shared/                               String catalog used by both apps
```

- Open `Package.swift` in Xcode 16+ to work on the library and press **⌘U** to run the tests on an iOS simulator.
- Open `Example/BiometricAuthenticationExample.xcodeproj` and pick the **UIKitExample** or **SwiftUIExample** scheme to run an example app. The project adds the repository root as a local Swift package dependency, so edits to `Sources/` are picked up directly. The examples are not part of the package and are never built by apps that install it.
- See [CHANGELOG.md](CHANGELOG.md) for the full version history.

## License

BiometricAuthentication is released under the MIT license. [See LICENSE](https://github.com/rushisangani/BiometricAuthentication/blob/master/LICENSE) for details.

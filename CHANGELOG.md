# Changelog

All notable changes to this project are documented in this file.
This project follows [Semantic Versioning](https://semver.org).

## [4.1.0]

### Fixed
- Starting a new authentication invalidates the one still in progress on the same authenticator, which fails with `canceledByApp`, instead of leaving a stale `LAContext` that could loop or block retries ([#46](https://github.com/rushisangani/BiometricAuthentication/issues/46), [#45](https://github.com/rushisangani/BiometricAuthentication/issues/45)).
- `biometryNotAvailable` on a Face ID device, usually caused by denying the app's Face ID permission, now shows a Face ID message pointing to Settings (new key `faceid.not.available`) instead of saying the device has no biometry ([#40](https://github.com/rushisangani/BiometricAuthentication/issues/40)).
- The library compiles in Swift 6 language mode.

## [4.0.0]

### Added
- async/await APIs: `authenticateWithBiometrics(reason:fallbackTitle:cancelTitle:)` and `authenticateWithPasscode(reason:cancelTitle:)`.
- Localized messages looked up in a custom bundle and strings table via `BiometricAuthenticator(bundle:tableName:)`, with English defaults for missing keys.
- `AuthenticationError.message(using:)` and `LocalizedError` conformance.
- New `AuthenticationError` cases: `canceledByApp`, `invalidContext`, `notInteractive`, `companionNotAvailable`.
- Optic ID support: `opticIDAvailable()`, `isOpticIDDevice()`.
- Swift Package Manager support, privacy manifest, DocC documentation and unit tests.

### Changed
- Create and configure your own `BiometricAuthenticator` instances instead of using the shared singleton.
- Completion-handler variants are now instance methods and are called on the main actor.
- `authenticateWithBioMetrics` is renamed to `authenticateWithBiometrics`, and `AuthenticationError.initWithError(_:)` to `AuthenticationError(_:)`.
- `isFaceIdDevice()` is renamed to `isFaceIDDevice()`, matching `faceIDAvailable()` and Apple's `faceID` naming.
- Authentication no longer reports a `Bool` that was always `true`: the async APIs return `Void` and throw on failure, and completion handlers receive `Result<Void, AuthenticationError>`.
- Minimum deployment target is iOS 15.0.

### Removed
- `BioMetricAuthenticator.shared` singleton and static authentication functions.
- Carthage support and the Xcode framework project. Use Swift Package Manager or CocoaPods.

### Deprecated
- `BioMetricAuthenticator`; use `BiometricAuthenticator`.

### Fixed
- `allowableReuseDuration` is clamped to `0...LATouchIDAuthenticationMaximumAllowableReuseDuration` (5 minutes), matching what `LAContext` supports.
- Passcode and authentication reasons now show the Face ID message on Face ID devices when biometry is locked out or not enrolled.

## [3.1]
- Updated to Swift 5.0.
- Implemented `Result` type as completion callback.

## [2.2]
- Added `allowableReuseDuration`.

## [2.1]
- Check if Touch ID or Face ID authentication is available.

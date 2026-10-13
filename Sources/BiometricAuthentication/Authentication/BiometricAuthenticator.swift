//
//  BiometricAuthenticator.swift
//  BiometricAuthentication
//
//  Copyright (c) 2018 Rushi Sangani
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import LocalAuthentication

/// Performs biometric (Touch ID, Face ID, Optic ID) and device-passcode authentication.
public struct BiometricAuthenticator: Sendable {

    // MARK: - Properties
    
    /// Duration (in seconds) for which a successful Touch ID or Face ID unlock on the device lock screen is reused, so biometric authentication succeeds without prompting again. Defaults to `0` (no reuse).
    ///
    /// Only lock-screen unlocks are reused, not previous biometric matches in the app. The value is clamped to `0...LATouchIDAuthenticationMaximumAllowableReuseDuration` (5 minutes).
    public var allowableReuseDuration: TimeInterval = 0
    
    var bundle: Bundle
    var tableName: String
    
    /// Creates the `LAContext` used for each check and evaluation. Replaced in tests.
    var makeContext: @Sendable () -> LAContext = { LAContext() }
    
    /// Creates an authenticator that resolves its localized messages from the given bundle and strings table.
    /// - Parameters:
    ///   - bundle: Bundle containing the localized strings. Defaults to `.main`.
    ///   - tableName: Name of the strings table (`.strings` / `.xcstrings`) to look up keys in. Defaults to `"Localizable"`.
    public init(bundle: Bundle = .main, tableName: String = "Localizable") {
        self.bundle = bundle
        self.tableName = tableName
    }
}

// MARK: - Public (async/await)

public extension BiometricAuthenticator {

    /// Checks if biometric authentication can be performed currently on the device.
    /// - Returns: `true` when biometry is available and enrolled, otherwise `false`.
    static func canAuthenticate() -> Bool {
        canAuthenticate(context: LAContext())
    }

    /// Perform biometric authentication using Swift Concurrency.
    /// - Parameters:
    ///   - reason: Reason shown in the authentication prompt. Pass an empty string to use the default localized reason for the device's biometry type.
    ///   - fallbackTitle: Title of the fallback button. `""` hides the button, `nil` shows the system default.
    ///   - cancelTitle: Title of the cancel button. `nil` or `""` shows the system default.
    /// - Throws: `AuthenticationError` describing the failure reason. Returns normally when authentication succeeds.
    func authenticateWithBiometrics(reason: String, fallbackTitle: String? = "", cancelTitle: String? = "") async throws {
        let reasonString = reason.isEmpty ? defaultBiometricAuthenticationReason() : reason

        let context = makeContext()
        context.touchIDAuthenticationAllowableReuseDuration = clampedReuseDuration
        context.localizedFallbackTitle = fallbackTitle
        context.localizedCancelTitle = cancelTitle

        try await evaluate(policy: .deviceOwnerAuthenticationWithBiometrics, with: context, reason: reasonString)
    }

    /// Perform device-passcode authentication using Swift Concurrency.
    /// - Parameters:
    ///   - reason: Reason shown in the authentication prompt. Pass an empty string to use the default localized reason for the device's biometry type.
    ///   - cancelTitle: Title of the cancel button. `nil` or `""` shows the system default.
    /// - Throws: `AuthenticationError` describing the failure reason. Returns normally when authentication succeeds.
    func authenticateWithPasscode(reason: String, cancelTitle: String? = "") async throws {
        let reasonString = reason.isEmpty ? defaultPasscodeAuthenticationReason() : reason

        let context = makeContext()
        context.localizedCancelTitle = cancelTitle

        try await evaluate(policy: .deviceOwnerAuthentication, with: context, reason: reasonString)
    }

    /// Checks if device supports Face ID and authentication can be done.
    /// - Returns: `true` when the device has Face ID and it is available and enrolled, otherwise `false`.
    func faceIDAvailable() -> Bool {
        let context = makeContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate && context.biometryType == .faceID
    }

    /// Checks if device supports Touch ID and authentication can be done.
    /// - Returns: `true` when the device has Touch ID and it is available and enrolled, otherwise `false`.
    func touchIDAvailable() -> Bool {
        let context = makeContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate && context.biometryType == .touchID
    }

    /// Checks if device supports Optic ID (Apple Vision Pro) and authentication can be done.
    /// - Returns: `true` when the device has Optic ID and it is available and enrolled, otherwise `false`. Always `false` below iOS 17 / visionOS 1.
    func opticIDAvailable() -> Bool {
        guard #available(iOS 17.0, visionOS 1.0, *) else { return false }
        let context = makeContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate && context.biometryType == .opticID
    }

    /// Checks if device has Face ID hardware (regardless of enrollment/availability).
    /// - Returns: `true` when the device's biometry type is Face ID, otherwise `false`.
    func isFaceIDDevice() -> Bool {
        let context = makeContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType == .faceID
    }

    /// Checks if device has Optic ID hardware (regardless of enrollment/availability).
    /// - Returns: `true` when the device's biometry type is Optic ID, otherwise `false`. Always `false` below iOS 17 / visionOS 1.
    func isOpticIDDevice() -> Bool {
        guard #available(iOS 17.0, visionOS 1.0, *) else { return false }
        let context = makeContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType == .opticID
    }
}

// MARK: - Public (completion handlers)

public extension BiometricAuthenticator {

    /// Completion-handler variant of ``authenticateWithBiometrics(reason:fallbackTitle:cancelTitle:)``.
    /// - Parameters:
    ///   - reason: Reason shown in the authentication prompt. Pass an empty string to use the default localized reason for the device's biometry type.
    ///   - fallbackTitle: Title of the fallback button. `""` hides the button, `nil` shows the system default.
    ///   - cancelTitle: Title of the cancel button. `nil` or `""` shows the system default.
    ///   - completion: Called on the main actor with `.success` when authentication succeeds, or `.failure` with the `AuthenticationError` describing the failure reason.
    func authenticateWithBiometrics(reason: String, fallbackTitle: String? = "", cancelTitle: String? = "", completion: @escaping @MainActor @Sendable (Result<Void, AuthenticationError>) -> Void) {
        Task { @MainActor in
            do {
                try await authenticateWithBiometrics(reason: reason, fallbackTitle: fallbackTitle, cancelTitle: cancelTitle)
                completion(.success(()))
            } catch let error as AuthenticationError {
                completion(.failure(error))
            } catch {
                completion(.failure(.other))
            }
        }
    }

    /// Completion-handler variant of ``authenticateWithPasscode(reason:cancelTitle:)``.
    /// - Parameters:
    ///   - reason: Reason shown in the authentication prompt. Pass an empty string to use the default localized reason for the device's biometry type.
    ///   - cancelTitle: Title of the cancel button. `nil` or `""` shows the system default.
    ///   - completion: Called on the main actor with `.success` when authentication succeeds, or `.failure` with the `AuthenticationError` describing the failure reason.
    func authenticateWithPasscode(reason: String, cancelTitle: String? = "", completion: @escaping @MainActor @Sendable (Result<Void, AuthenticationError>) -> Void) {
        Task { @MainActor in
            do {
                try await authenticateWithPasscode(reason: reason, cancelTitle: cancelTitle)
                completion(.success(()))
            } catch let error as AuthenticationError {
                completion(.failure(error))
            } catch {
                completion(.failure(.other))
            }
        }
    }
}

// MARK: - Internal

extension BiometricAuthenticator {

    /// ``allowableReuseDuration`` limited to the range `LAContext` supports.
    var clampedReuseDuration: TimeInterval {
        min(max(allowableReuseDuration, 0), LATouchIDAuthenticationMaximumAllowableReuseDuration)
    }

    /// Checks if biometric authentication can be performed with the given context.
    static func canAuthenticate(context: LAContext) -> Bool {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate && error == nil
    }

    /// Looks up `text.key` in `tableName` within `bundle`, falling back to `text.defaultValue` when missing.
    func localizedString(_ text: LocalizedText) -> String {
        NSLocalizedString(text.key, tableName: tableName, bundle: bundle, value: text.defaultValue, comment: "")
    }
}

// MARK: - Private

private extension BiometricAuthenticator {

    func defaultBiometricAuthenticationReason() -> String {
        if isOpticIDDevice() { return localizedString(kOpticIdAuthenticationReason) }
        return localizedString(isFaceIDDevice() ? kFaceIdAuthenticationReason : kTouchIdAuthenticationReason)
    }

    func defaultPasscodeAuthenticationReason() -> String {
        if isOpticIDDevice() { return localizedString(kOpticIdPasscodeAuthenticationReason) }
        return localizedString(isFaceIDDevice() ? kFaceIdPasscodeAuthenticationReason : kTouchIdPasscodeAuthenticationReason)
    }

    /// Evaluates an `LAPolicy` using Swift Concurrency, mapping `LAError` into ``AuthenticationError``.
    func evaluate(policy: LAPolicy, with context: LAContext, reason: String) async throws {
        let result: Result<Void, AuthenticationError> = await withCheckedContinuation { continuation in
            context.evaluatePolicy(policy, localizedReason: reason) { success, error in
                continuation.resume(returning: success ? .success(()) : .failure(AuthenticationError(error)))
            }
        }
        try result.get()
    }
}

// MARK: - Backward compatibility

@available(*, deprecated, renamed: "BiometricAuthenticator")
public typealias BioMetricAuthenticator = BiometricAuthenticator


//
//  AuthenticationErrors.swift
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

/// Authentication errors thrown or returned by ``BiometricAuthenticator``, mirroring `LAError.Code`.
public enum AuthenticationError: Error, Sendable {

    /// The user failed to provide valid credentials (`LAError.authenticationFailed`).
    case failed
    /// The user tapped the cancel button (`LAError.userCancel`).
    case canceledByUser
    /// The user tapped the fallback button (`LAError.userFallback`).
    case fallback
    /// The system canceled authentication, e.g. another app came to the foreground (`LAError.systemCancel`).
    case canceledBySystem
    /// The app canceled authentication by invalidating the context (`LAError.appCancel`).
    case canceledByApp
    /// A passcode isn't set on the device (`LAError.passcodeNotSet`).
    case passcodeNotSet
    /// Biometry isn't available on the device (`LAError.biometryNotAvailable`).
    case biometryNotAvailable
    /// The user has no enrolled biometric identities (`LAError.biometryNotEnrolled`).
    case biometryNotEnrolled
    /// Biometry is locked because there were too many failed attempts (`LAError.biometryLockout`).
    case biometryLockedout
    /// The context was previously invalidated (`LAError.invalidContext`).
    case invalidContext
    /// Displaying the required authentication UI is forbidden (`LAError.notInteractive`).
    case notInteractive
    /// No paired companion device (e.g. Apple Watch) is nearby to authenticate (`LAError.companionNotAvailable`).
    case companionNotAvailable
    /// Any other, unmapped error.
    case other

    /// Creates the ``AuthenticationError`` matching a `LocalAuthentication` error.
    /// - Parameter error: The `LAError` returned by `LAContext`. Unmapped codes become ``other``.
    public init(_ error: LAError) {
        self = switch Int32(error.errorCode) {
        case kLAErrorAuthenticationFailed: .failed
        case kLAErrorUserCancel: .canceledByUser
        case kLAErrorUserFallback: .fallback
        case kLAErrorSystemCancel: .canceledBySystem
        case kLAErrorAppCancel: .canceledByApp
        case kLAErrorPasscodeNotSet: .passcodeNotSet
        case kLAErrorBiometryNotAvailable: .biometryNotAvailable
        case kLAErrorBiometryNotEnrolled: .biometryNotEnrolled
        case kLAErrorBiometryLockout: .biometryLockedout
        case kLAErrorInvalidContext: .invalidContext
        case kLAErrorNotInteractive: .notInteractive
        case kLAErrorWatchNotAvailable: .companionNotAvailable // same code as `kLAErrorCompanionNotAvailable`, which needs the iOS 18 SDK
        default: .other
        }
    }

    /// Creates the ``AuthenticationError`` matching any error returned by `LAContext`.
    /// - Parameter error: The error returned by `LAContext`, or `nil`. Anything that isn't an `LAError` becomes ``other``.
    init(_ error: Error?) {
        guard let laError = error as? LAError else {
            self = .other
            return
        }
        self.init(laError)
    }

    /// Returns a human-readable message appropriate for the current device's biometry type (Optic ID, Face ID, or Touch ID).
    /// - Parameter authenticator: Authenticator whose `bundle` and `tableName` are used to look up the localized message. Defaults to one using the main bundle and `"Localizable"` table.
    /// - Returns: The localized message, or an empty string for user, system or app cancellation and fallback.
    public func message(using authenticator: BiometricAuthenticator = BiometricAuthenticator()) -> String {
        let isOpticIDDevice = authenticator.isOpticIDDevice()
        let isFaceIDDevice = authenticator.isFaceIDDevice()

        switch self {
        case .canceledByUser, .fallback, .canceledBySystem, .canceledByApp:
            return ""

        case .passcodeNotSet:
            if isOpticIDDevice { return authenticator.localizedString(kSetPasscodeToUseOpticID) }
            return authenticator.localizedString(isFaceIDDevice ? kSetPasscodeToUseFaceID : kSetPasscodeToUseTouchID)

        case .biometryNotAvailable:
            return authenticator.localizedString(kBiometryNotAvailableReason)

        case .companionNotAvailable:
            return authenticator.localizedString(kCompanionNotAvailableReason)

        case .biometryNotEnrolled:
            if isOpticIDDevice { return authenticator.localizedString(kNoOpticIdentityEnrolled) }
            return authenticator.localizedString(isFaceIDDevice ? kNoFaceIdentityEnrolled : kNoFingerprintEnrolled)

        case .biometryLockedout:
            if isOpticIDDevice { return authenticator.localizedString(kOpticIdPasscodeAuthenticationReason) }
            return authenticator.localizedString(isFaceIDDevice ? kFaceIdPasscodeAuthenticationReason : kTouchIdPasscodeAuthenticationReason)

        default:
            if isOpticIDDevice { return authenticator.localizedString(kDefaultOpticIDAuthenticationFailedReason) }
            return authenticator.localizedString(isFaceIDDevice ? kDefaultFaceIDAuthenticationFailedReason : kDefaultTouchIDAuthenticationFailedReason)
        }
    }
}

// MARK: - LocalizedError

extension AuthenticationError: LocalizedError {

    /// Localized description of the error using the main bundle and `"Localizable"` table, or `nil` for cancellation and fallback.
    public var errorDescription: String? {
        let text = message()
        return text.isEmpty ? nil : text
    }
}

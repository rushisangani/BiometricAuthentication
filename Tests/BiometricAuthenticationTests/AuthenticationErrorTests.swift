//
//  AuthenticationErrorTests.swift
//  BiometricAuthenticationTests
//

import Foundation
import LocalAuthentication
import Testing
@testable import BiometricAuthentication

@Suite("AuthenticationError")
struct AuthenticationErrorTests {

    @Test("Maps LAError codes", arguments: [
        (kLAErrorAuthenticationFailed, AuthenticationError.failed),
        (kLAErrorUserCancel, .canceledByUser),
        (kLAErrorUserFallback, .fallback),
        (kLAErrorSystemCancel, .canceledBySystem),
        (kLAErrorAppCancel, .canceledByApp),
        (kLAErrorPasscodeNotSet, .passcodeNotSet),
        (kLAErrorBiometryNotAvailable, .biometryNotAvailable),
        (kLAErrorBiometryNotEnrolled, .biometryNotEnrolled),
        (kLAErrorBiometryLockout, .biometryLockedout),
        (kLAErrorInvalidContext, .invalidContext),
        (kLAErrorNotInteractive, .notInteractive),
        (kLAErrorWatchNotAvailable, .companionNotAvailable),
    ])
    func mapsLAErrorCode(code: Int32, expected: AuthenticationError) {
        #expect(AuthenticationError(laError(code)) == expected)
    }

    @Test("Maps unknown LAError code to other")
    func mapsUnknownCodeToOther() {
        #expect(AuthenticationError(laError(-9999)) == .other)
    }

    @Test("Maps missing or non-LAError errors to other")
    func mapsNonLAErrorToOther() {
        #expect(AuthenticationError(nil) == .other)
        #expect(AuthenticationError(URLError(.badURL)) == .other)
    }

    @Test("Cancellation and fallback have no message", arguments: [AuthenticationError.canceledByUser, .canceledBySystem, .canceledByApp, .fallback])
    func cancellationHasNoMessage(error: AuthenticationError) {
        #expect(error.message().isEmpty)
        #expect(error.errorDescription == nil)
    }

    @Test("Failures have a message", arguments: [AuthenticationError.failed, .passcodeNotSet, .biometryNotAvailable, .biometryNotEnrolled, .biometryLockedout, .invalidContext, .notInteractive, .companionNotAvailable, .other])
    func failureHasMessage(error: AuthenticationError) {
        #expect(!error.message().isEmpty)
        #expect(error.errorDescription == error.message())
    }

    // MARK: - Helpers

    /// Builds the error the way `LAContext` delivers it: an `NSError` in the `LAError` domain.
    private func laError(_ code: Int32) -> Error {
        NSError(domain: LAErrorDomain, code: Int(code))
    }
}

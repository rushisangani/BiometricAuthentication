//
//  LocalizationTests.swift
//  BiometricAuthenticationTests
//

import Foundation
import Testing
@testable import BiometricAuthentication

@Suite("Localization")
struct LocalizationTests {

    @Test("Uses the authenticator's bundle and table")
    func usesCustomBundleAndTable() {
        let authenticator = makeAuthenticator(tableName: "TestStrings")

        #expect(AuthenticationError.biometryNotAvailable.message(using: authenticator) == "Custom biometry not available")
        #expect(AuthenticationError.companionNotAvailable.message(using: authenticator) == "Custom companion not available")
    }

    @Test("Falls back to the default value for a missing key")
    func fallsBackForMissingKey() {
        let authenticator = makeAuthenticator(tableName: "TestStrings")

        #expect(authenticator.localizedString(kNoFaceIdentityEnrolled) == kNoFaceIdentityEnrolled.defaultValue)
    }

    @Test("Falls back to the default value for a missing table")
    func fallsBackForMissingTable() {
        let authenticator = makeAuthenticator(tableName: "MissingTable")

        #expect(AuthenticationError.biometryNotAvailable.message(using: authenticator) == kBiometryNotAvailableReason.defaultValue)
    }

    // MARK: - Helpers

    /// Returns an authenticator on a device without biometry, so messages don't depend on the simulator's biometry type.
    private func makeAuthenticator(tableName: String) -> BiometricAuthenticator {
        BiometricAuthenticator(bundle: .module, tableName: tableName, makeContext: { MockLAContext() })
    }
}

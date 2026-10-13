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
        let authenticator = BiometricAuthenticator(bundle: .module, tableName: "TestStrings")

        #expect(AuthenticationError.biometryNotAvailable.message(using: authenticator) == "Custom biometry not available")
        #expect(AuthenticationError.companionNotAvailable.message(using: authenticator) == "Custom companion not available")
    }

    @Test("Falls back to the default value for a missing key")
    func fallsBackForMissingKey() {
        let authenticator = BiometricAuthenticator(bundle: .module, tableName: "TestStrings")

        #expect(authenticator.localizedString(kNoFaceIdentityEnrolled) == kNoFaceIdentityEnrolled.defaultValue)
    }

    @Test("Falls back to the default value for a missing table")
    func fallsBackForMissingTable() {
        let authenticator = BiometricAuthenticator(bundle: .module, tableName: "MissingTable")

        #expect(AuthenticationError.biometryNotAvailable.message(using: authenticator) == kBiometryNotAvailableReason.defaultValue)
    }
}

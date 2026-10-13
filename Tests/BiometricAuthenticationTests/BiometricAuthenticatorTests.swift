//
//  BiometricAuthenticatorTests.swift
//  BiometricAuthenticationTests
//

import Foundation
import LocalAuthentication
import Testing
@testable import BiometricAuthentication

@Suite("BiometricAuthenticator")
struct BiometricAuthenticatorTests {

    // MARK: - Configuration

    @Test("Defaults to no reuse duration")
    func allowableReuseDurationDefaultsToZero() {
        #expect(BiometricAuthenticator().allowableReuseDuration == 0)
    }

    @Test("Each instance keeps its own configuration")
    func instancesAreIndependent() {
        var first = BiometricAuthenticator()
        let second = first
        first.allowableReuseDuration = 30

        #expect(first.allowableReuseDuration == 30)
        #expect(second.allowableReuseDuration == 0)
    }

    // MARK: - Biometric authentication

    @Test("Biometric authentication succeeds with the given reason")
    func biometricSuccess() async throws {
        let context = MockLAContext()
        let authenticator = makeAuthenticator(context)

        try await authenticator.authenticateWithBiometrics(reason: "Log in")

        #expect(context.evaluatedPolicy == .deviceOwnerAuthenticationWithBiometrics)
        #expect(context.evaluatedReason == "Log in")
    }

    @Test("Biometric authentication configures the context")
    func biometricConfiguresContext() async throws {
        let context = MockLAContext()
        var authenticator = makeAuthenticator(context)
        authenticator.allowableReuseDuration = 30

        try await authenticator.authenticateWithBiometrics(reason: "Log in", fallbackTitle: "Use Password", cancelTitle: "Not Now")

        #expect(context.setReuseDuration == 30)
        #expect(context.localizedFallbackTitle == "Use Password")
        #expect(context.localizedCancelTitle == "Not Now")
    }

    @Test("Biometric authentication disables lock-screen reuse by default")
    func biometricReuseDurationDefault() async throws {
        let context = MockLAContext()

        try await makeAuthenticator(context).authenticateWithBiometrics(reason: "Log in")

        #expect(context.setReuseDuration == 0)
    }

    @Test("Reuse duration is clamped to the range LAContext supports", arguments: [
        (-10.0, 0.0),
        (0, 0),
        (30, 30),
        (LATouchIDAuthenticationMaximumAllowableReuseDuration, LATouchIDAuthenticationMaximumAllowableReuseDuration),
        (600, LATouchIDAuthenticationMaximumAllowableReuseDuration),
    ])
    func reuseDurationIsClamped(duration: TimeInterval, expected: TimeInterval) async throws {
        let context = MockLAContext()
        var authenticator = makeAuthenticator(context)
        authenticator.allowableReuseDuration = duration

        try await authenticator.authenticateWithBiometrics(reason: "Log in")

        #expect(authenticator.allowableReuseDuration == duration)
        #expect(context.setReuseDuration == expected)
    }

    @Test("Each authentication uses a new context with the current reuse duration")
    func reuseDurationAppliedToEveryNewContext() async throws {
        let contexts = ContextFactory()
        var authenticator = BiometricAuthenticator(bundle: .module, tableName: "MissingTable")
        authenticator.makeContext = { contexts.make() }
        authenticator.allowableReuseDuration = 60

        try await authenticator.authenticateWithBiometrics(reason: "First")
        try await authenticator.authenticateWithBiometrics(reason: "Second")

        let evaluated = contexts.made.filter { $0.evaluatedReason != nil }
        #expect(evaluated.map(\.evaluatedReason) == ["First", "Second"])
        #expect(evaluated.map(\.setReuseDuration) == [60, 60])
        #expect(evaluated[0] !== evaluated[1])
    }

    @Test("Biometric authentication hides the fallback button by default")
    func biometricHidesFallbackByDefault() async throws {
        let context = MockLAContext()

        try await makeAuthenticator(context).authenticateWithBiometrics(reason: "Log in")

        #expect(context.localizedFallbackTitle == "")
    }

    @Test("Empty reason uses the default for the device", arguments: [
        (LABiometryType.faceID, kFaceIdAuthenticationReason.defaultValue),
        (.touchID, kTouchIdAuthenticationReason.defaultValue),
        (.none, kTouchIdAuthenticationReason.defaultValue),
    ])
    func biometricDefaultReason(biometryType: LABiometryType, expectedReason: String) async throws {
        let context = MockLAContext()
        context.stubbedBiometryType = biometryType

        try await makeAuthenticator(context).authenticateWithBiometrics(reason: "")

        #expect(context.evaluatedReason == expectedReason)
    }

    @Test("Empty reason uses the Optic ID default on Optic ID devices")
    func biometricDefaultReasonOpticID() async throws {
        guard #available(iOS 17.0, *) else { return }
        let context = MockLAContext()
        context.stubbedBiometryType = .opticID

        try await makeAuthenticator(context).authenticateWithBiometrics(reason: "")

        #expect(context.evaluatedReason == kOpticIdAuthenticationReason.defaultValue)
    }

    @Test("Empty reason uses the Face ID default even when Face ID is unavailable")
    func biometricDefaultReasonWhenFaceIDUnavailable() async throws {
        let context = MockLAContext()
        context.stubbedBiometryType = .faceID
        context.canEvaluate = false

        try await makeAuthenticator(context).authenticateWithBiometrics(reason: "")

        #expect(context.evaluatedReason == kFaceIdAuthenticationReason.defaultValue)
    }

    @Test("Biometric failure throws the mapped error", arguments: [
        (kLAErrorAuthenticationFailed, AuthenticationError.failed),
        (kLAErrorUserCancel, .canceledByUser),
        (kLAErrorUserFallback, .fallback),
        (kLAErrorBiometryLockout, .biometryLockedout),
        (kLAErrorBiometryNotEnrolled, .biometryNotEnrolled),
    ])
    func biometricFailure(code: Int32, expected: AuthenticationError) async {
        let context = MockLAContext()
        context.evaluateSuccess = false
        context.evaluateError = MockLAContext.laError(code)

        await #expect(throws: expected) {
            try await makeAuthenticator(context).authenticateWithBiometrics(reason: "Log in")
        }
    }

    @Test("Biometric failure without an LAError throws other")
    func biometricFailureWithoutLAError() async {
        let context = MockLAContext()
        context.evaluateSuccess = false
        context.evaluateError = URLError(.badURL)

        await #expect(throws: AuthenticationError.other) {
            try await makeAuthenticator(context).authenticateWithBiometrics(reason: "Log in")
        }
    }

    // MARK: - Passcode authentication

    @Test("Passcode authentication uses the device owner policy")
    func passcodeSuccess() async throws {
        let context = MockLAContext()

        try await makeAuthenticator(context).authenticateWithPasscode(reason: "Unlock", cancelTitle: "Not Now")

        #expect(context.evaluatedPolicy == .deviceOwnerAuthentication)
        #expect(context.evaluatedReason == "Unlock")
        #expect(context.localizedCancelTitle == "Not Now")
        #expect(context.setReuseDuration == nil) // lock-screen reuse only applies to biometric authentication
    }

    @Test("Empty passcode reason uses the default for the device", arguments: [
        (LABiometryType.faceID, kFaceIdPasscodeAuthenticationReason.defaultValue),
        (.touchID, kTouchIdPasscodeAuthenticationReason.defaultValue),
    ])
    func passcodeDefaultReason(biometryType: LABiometryType, expectedReason: String) async throws {
        let context = MockLAContext()
        context.stubbedBiometryType = biometryType
        context.canEvaluate = false // biometry is locked out when falling back to passcode

        try await makeAuthenticator(context).authenticateWithPasscode(reason: "")

        #expect(context.evaluatedReason == expectedReason)
    }

    @Test("Passcode failure throws the mapped error")
    func passcodeFailure() async {
        let context = MockLAContext()
        context.evaluateSuccess = false
        context.evaluateError = MockLAContext.laError(kLAErrorPasscodeNotSet)

        await #expect(throws: AuthenticationError.passcodeNotSet) {
            try await makeAuthenticator(context).authenticateWithPasscode(reason: "Unlock")
        }
    }

    // MARK: - Completion handlers

    @Test("Biometric completion handler delivers success on the main thread")
    func biometricCompletionSuccess() async {
        let authenticator = makeAuthenticator(MockLAContext())

        let (result, isMainThread) = await withCheckedContinuation { continuation in
            authenticator.authenticateWithBiometrics(reason: "Log in") { result in
                continuation.resume(returning: (result, Thread.isMainThread))
            }
        }

        #expect(throws: Never.self) { try result.get() }
        #expect(isMainThread)
    }

    @Test("Passcode completion handler delivers the mapped error on the main thread")
    func passcodeCompletionFailure() async {
        let context = MockLAContext()
        context.evaluateSuccess = false
        context.evaluateError = MockLAContext.laError(kLAErrorUserCancel)
        let authenticator = makeAuthenticator(context)

        let (result, isMainThread) = await withCheckedContinuation { continuation in
            authenticator.authenticateWithPasscode(reason: "Unlock") { result in
                continuation.resume(returning: (result, Thread.isMainThread))
            }
        }

        #expect(throws: AuthenticationError.canceledByUser) { try result.get() }
        #expect(isMainThread)
    }

    // MARK: - Availability

    struct AvailabilityCase: Sendable, CustomTestStringConvertible {
        let biometryType: LABiometryType
        let canEvaluate: Bool
        let faceID: Bool
        let touchID: Bool

        var testDescription: String { "biometryType: \(biometryType.rawValue), canEvaluate: \(canEvaluate)" }
    }

    @Test("Biometry availability", arguments: [
        AvailabilityCase(biometryType: .faceID, canEvaluate: true, faceID: true, touchID: false),
        AvailabilityCase(biometryType: .faceID, canEvaluate: false, faceID: false, touchID: false),
        AvailabilityCase(biometryType: .touchID, canEvaluate: true, faceID: false, touchID: true),
        AvailabilityCase(biometryType: .touchID, canEvaluate: false, faceID: false, touchID: false),
        AvailabilityCase(biometryType: .none, canEvaluate: true, faceID: false, touchID: false),
    ])
    func biometryAvailability(_ testCase: AvailabilityCase) {
        let context = MockLAContext()
        context.stubbedBiometryType = testCase.biometryType
        context.canEvaluate = testCase.canEvaluate
        let authenticator = makeAuthenticator(context)

        #expect(authenticator.faceIDAvailable() == testCase.faceID)
        #expect(authenticator.touchIDAvailable() == testCase.touchID)
        #expect(!authenticator.opticIDAvailable())
    }

    @Test("Optic ID availability")
    func opticIDAvailability() {
        guard #available(iOS 17.0, *) else { return }
        let context = MockLAContext()
        context.stubbedBiometryType = .opticID
        let authenticator = makeAuthenticator(context)

        #expect(authenticator.opticIDAvailable())
        #expect(authenticator.isOpticIDDevice())

        context.canEvaluate = false
        #expect(!authenticator.opticIDAvailable())
        #expect(authenticator.isOpticIDDevice())
    }

    @Test("Hardware checks ignore availability", arguments: [true, false])
    func hardwareChecks(canEvaluate: Bool) {
        let context = MockLAContext()
        context.stubbedBiometryType = .faceID
        context.canEvaluate = canEvaluate
        let authenticator = makeAuthenticator(context)

        #expect(authenticator.isFaceIDDevice())
        #expect(!authenticator.isOpticIDDevice())
    }

    @Test("Can authenticate only when the policy evaluates without error")
    func canAuthenticate() {
        let context = MockLAContext()
        #expect(BiometricAuthenticator.canAuthenticate(context: context))

        context.canEvaluate = false
        #expect(!BiometricAuthenticator.canAuthenticate(context: context))

        context.canEvaluate = true
        context.canEvaluateError = MockLAContext.laError(kLAErrorBiometryNotEnrolled)
        #expect(!BiometricAuthenticator.canAuthenticate(context: context))
    }

    // MARK: - Error messages

    struct MessageCase: Sendable, CustomTestStringConvertible {
        let biometryType: LABiometryType
        let error: AuthenticationError
        let expected: LocalizedText

        var testDescription: String { "\(error) on biometryType \(biometryType.rawValue)" }
    }

    @Test("Error messages match the device's biometry type", arguments: [
        MessageCase(biometryType: .faceID, error: .biometryLockedout, expected: kFaceIdPasscodeAuthenticationReason),
        MessageCase(biometryType: .touchID, error: .biometryLockedout, expected: kTouchIdPasscodeAuthenticationReason),
        MessageCase(biometryType: .faceID, error: .biometryNotEnrolled, expected: kNoFaceIdentityEnrolled),
        MessageCase(biometryType: .touchID, error: .biometryNotEnrolled, expected: kNoFingerprintEnrolled),
        MessageCase(biometryType: .faceID, error: .passcodeNotSet, expected: kSetPasscodeToUseFaceID),
        MessageCase(biometryType: .touchID, error: .failed, expected: kDefaultTouchIDAuthenticationFailedReason),
    ])
    func errorMessage(_ testCase: MessageCase) {
        let context = MockLAContext()
        context.stubbedBiometryType = testCase.biometryType
        context.canEvaluate = false // messages must not depend on biometry being available

        #expect(testCase.error.message(using: makeAuthenticator(context)) == testCase.expected.defaultValue)
    }

    // MARK: - Helpers

    /// Hands out a new `MockLAContext` on every call and keeps them for inspection.
    final class ContextFactory: @unchecked Sendable {
        private let lock = NSLock()
        private var contexts: [MockLAContext] = []

        var made: [MockLAContext] {
            lock.lock()
            defer { lock.unlock() }
            return contexts
        }

        func make() -> MockLAContext {
            let context = MockLAContext()
            lock.lock()
            defer { lock.unlock() }
            contexts.append(context)
            return context
        }
    }

    /// Returns an authenticator that uses `context` and the built-in English messages.
    private func makeAuthenticator(_ context: MockLAContext) -> BiometricAuthenticator {
        var authenticator = BiometricAuthenticator(bundle: .module, tableName: "MissingTable")
        authenticator.makeContext = { context }
        return authenticator
    }
}

//
//  MockLAContext.swift
//  BiometricAuthenticationTests
//

import Foundation
import LocalAuthentication

/// An `LAContext` whose biometry type and evaluation results are controlled by the test.
final class MockLAContext: LAContext, @unchecked Sendable {

    // MARK: - Stubs

    var stubbedBiometryType: LABiometryType = .none
    var canEvaluate = true
    var canEvaluateError: NSError?
    var evaluateSuccess = true
    var evaluateError: Error?
    /// When `true`, evaluation stays in progress until the context is invalidated, like a prompt left on screen.
    var holdsReply = false
    /// Called when evaluation starts.
    var onEvaluate: (@Sendable () -> Void)?

    // MARK: - Recorded calls

    private(set) var evaluatedPolicy: LAPolicy?
    private(set) var evaluatedReason: String?
    private(set) var setReuseDuration: TimeInterval?
    private(set) var isInvalidated = false

    private var pendingReply: (@Sendable (Bool, Error?) -> Void)?

    // MARK: - Overrides

    override var biometryType: LABiometryType { stubbedBiometryType }

    override var touchIDAuthenticationAllowableReuseDuration: TimeInterval {
        didSet { setReuseDuration = touchIDAuthenticationAllowableReuseDuration }
    }

    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        error?.pointee = canEvaluateError
        return canEvaluate
    }

    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping @Sendable (Bool, Error?) -> Void) {
        evaluatedPolicy = policy
        evaluatedReason = localizedReason
        if holdsReply {
            pendingReply = reply
        } else {
            reply(evaluateSuccess, evaluateError)
        }
        onEvaluate?()
    }

    override func invalidate() {
        isInvalidated = true
        let reply = pendingReply
        pendingReply = nil
        reply?(false, Self.laError(kLAErrorAppCancel))
    }
}

extension MockLAContext {

    /// Builds the error the way `LAContext` delivers it: an `NSError` in the `LAError` domain.
    static func laError(_ code: Int32) -> NSError {
        NSError(domain: LAErrorDomain, code: Int(code))
    }
}

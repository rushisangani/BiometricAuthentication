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

    // MARK: - Recorded calls

    private(set) var evaluatedPolicy: LAPolicy?
    private(set) var evaluatedReason: String?
    private(set) var setReuseDuration: TimeInterval?

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
        reply(evaluateSuccess, evaluateError)
    }
}

extension MockLAContext {

    /// Builds the error the way `LAContext` delivers it: an `NSError` in the `LAError` domain.
    static func laError(_ code: Int32) -> NSError {
        NSError(domain: LAErrorDomain, code: Int(code))
    }
}

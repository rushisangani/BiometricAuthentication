//
//  BioMetricAuthenticator.swift
//  BiometricAuthentication
//
//  Copyright (c) 2017 Rushi Sangani
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

import UIKit
import LocalAuthentication

open class BioMetricAuthenticator: NSObject {

    // MARK: - Singleton
    public static let shared = BioMetricAuthenticator()
}

// MARK:- Public

public extension BioMetricAuthenticator {
    
    /// checks if TouchID or FaceID is available on the device.
    class func canAuthenticate() -> Bool {
        
        var isBiometricAuthenticationAvailable = false
        var error: NSError? = nil
        
        if LAContext().canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAuthenticationAvailable = (error == nil)
        }
        return isBiometricAuthenticationAvailable
    }
    
    /// Check for biometric authentication
    class func authenticateWithBioMetrics(reason: String, fallbackTitle: String? = "", cancelTitle: String? = "", success successBlock:@escaping AuthenticationSuccess, failure failureBlock:@escaping AuthenticationFailure) {
        let reasonString = reason.isEmpty ? BioMetricAuthenticator.shared.defaultBiometricAuthenticationReason() : reason
        
        let context = LAContext()
        context.localizedFallbackTitle = fallbackTitle
        
        // cancel button title
        if #available(iOS 10.0, *) {
            context.localizedCancelTitle = cancelTitle
        }
        
        // authenticate
        BioMetricAuthenticator.shared.evaluate(policy: LAPolicy.deviceOwnerAuthenticationWithBiometrics, with: context, reason: reasonString, success: successBlock, failure: failureBlock)
    }
    
    /// Check for device passcode authentication
    class func authenticateWithPasscode(reason: String, cancelTitle: String? = "", success successBlock:@escaping AuthenticationSuccess, failure failureBlock:@escaping AuthenticationFailure) {
        let reasonString = reason.isEmpty ? BioMetricAuthenticator.shared.defaultPasscodeAuthenticationReason() : reason
        
        let context = LAContext()
        
        // cancel button title
        if #available(iOS 10.0, *) {
            context.localizedCancelTitle = cancelTitle
        }
        
        // authenticate
        BioMetricAuthenticator.shared.evaluate(policy: LAPolicy.deviceOwnerAuthentication, with: context, reason: reasonString, success: successBlock, failure: failureBlock)
    }
    
    /// checks if face id is avaiable on device
    public func faceIDAvailable() -> Bool {
        if #available(iOS 11.0, *) {
            let context = LAContext()
            return (context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil) && context.biometryType == .faceID)
        }
        return false
    }
}

// MARK:- Private
extension BioMetricAuthenticator {

    /// get authentication reason to show while authentication
    func defaultBiometricAuthenticationReason() -> String {
        return faceIDAvailable() ? kFaceIdAuthenticationReason : kTouchIdAuthenticationReason
    }
    
    /// get passcode authentication reason to show while entering device passcode after multiple failed attempts.
    func defaultPasscodeAuthenticationReason() -> String {
        return faceIDAvailable() ? kFaceIdPasscodeAuthenticationReason : kTouchIdPasscodeAuthenticationReason
    }
    
    /// evaluate policy
    func evaluate(policy: LAPolicy, with context: LAContext, reason: String, success successBlock:@escaping AuthenticationSuccess, failure failureBlock:@escaping AuthenticationFailure) {
        
        context.evaluatePolicy(policy, localizedReason: reason) { (success, err) in
            DispatchQueue.main.async {
                if success { successBlock() }
                else {
                    let errorType = AuthenticationError(error: err as! LAError)
                    failureBlock(errorType)
                }
            }
        }
    }
}

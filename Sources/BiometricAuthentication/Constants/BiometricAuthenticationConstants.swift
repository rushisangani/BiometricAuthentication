//
//  BiometricAuthenticationConstants.swift
//  BiometricAuthentication
//
//  Created by Rushi on 27/10/17.
//  Copyright © 2018 Rushi Sangani. All rights reserved.
//

import Foundation
import LocalAuthentication

/// A localization key paired with its English fallback text.
///
/// The framework does not ship any translations itself — host apps are expected to provide
/// their own entries in the table configured on ``BiometricAuthenticator`` (`tableName` in `bundle`).
/// If a key is missing, `defaultValue` is returned so the end user still sees sensible text.
struct LocalizedText: Sendable {
    let key: String
    let defaultValue: String
}

let kBiometryNotAvailableReason = LocalizedText(key: "biometry.not.available", defaultValue: "Biometric authentication is not available for this device.")
let kCompanionNotAvailableReason = LocalizedText(key: "companion.not.available", defaultValue: "No paired companion device is nearby. Please bring your Apple Watch closer and try again.")

/// ****************  Touch ID  ****************** ///

let kTouchIdAuthenticationReason = LocalizedText(key: "touchid.authentication.reason", defaultValue: "Confirm your fingerprint to authenticate.")
let kTouchIdPasscodeAuthenticationReason = LocalizedText(key: "touchid.passcode.authentication.reason", defaultValue: "Touch ID is locked now, because of too many failed attempts. Enter passcode to unlock Touch ID.")

/// Error Messages Touch ID
let kSetPasscodeToUseTouchID = LocalizedText(key: "touchid.set.passcode", defaultValue: "Please set device passcode to use Touch ID for authentication.")
let kNoFingerprintEnrolled = LocalizedText(key: "touchid.not.enrolled", defaultValue: "There are no fingerprints enrolled in the device. Please go to Device Settings -> Touch ID & Passcode and enroll your fingerprints.")
let kDefaultTouchIDAuthenticationFailedReason = LocalizedText(key: "touchid.failed.reason", defaultValue: "Touch ID does not recognize your fingerprint. Please try again with your enrolled fingerprint.")

/// ****************  Face ID  ****************** ///

let kFaceIdAuthenticationReason = LocalizedText(key: "faceid.authentication.reason", defaultValue: "Confirm your face to authenticate.")
let kFaceIdPasscodeAuthenticationReason = LocalizedText(key: "faceid.passcode.authentication.reason", defaultValue: "Face ID is locked now, because of too many failed attempts. Enter passcode to unlock Face ID.")

/// Error Messages Face ID
let kSetPasscodeToUseFaceID = LocalizedText(key: "faceid.set.passcode", defaultValue: "Please set device passcode to use Face ID for authentication.")
let kFaceIdNotAvailableReason = LocalizedText(key: "faceid.not.available", defaultValue: "Face ID is not available. Please allow this app to use Face ID in Settings.")
let kNoFaceIdentityEnrolled = LocalizedText(key: "faceid.not.enrolled", defaultValue: "There is no face enrolled in the device. Please go to Device Settings -> Face ID & Passcode and enroll your face.")
let kDefaultFaceIDAuthenticationFailedReason = LocalizedText(key: "faceid.failed.reason", defaultValue: "Face ID does not recognize your face. Please try again with your enrolled face.")

/// ****************  Optic ID  ****************** ///

let kOpticIdAuthenticationReason = LocalizedText(key: "opticid.authentication.reason", defaultValue: "Confirm your eyes to authenticate.")
let kOpticIdPasscodeAuthenticationReason = LocalizedText(key: "opticid.passcode.authentication.reason", defaultValue: "Optic ID is locked now, because of too many failed attempts. Enter passcode to unlock Optic ID.")

/// Error Messages Optic ID
let kSetPasscodeToUseOpticID = LocalizedText(key: "opticid.set.passcode", defaultValue: "Please set device passcode to use Optic ID for authentication.")
let kNoOpticIdentityEnrolled = LocalizedText(key: "opticid.not.enrolled", defaultValue: "There are no eyes enrolled in the device. Please go to Device Settings -> Optic ID & Passcode and enroll your eyes.")
let kDefaultOpticIDAuthenticationFailedReason = LocalizedText(key: "opticid.failed.reason", defaultValue: "Optic ID does not recognize your eyes. Please try again with your enrolled eyes.")

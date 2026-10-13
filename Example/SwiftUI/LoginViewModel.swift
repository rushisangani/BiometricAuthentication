//
//  LoginViewModel.swift
//  SwiftUI
//
//  Copyright © 2026 Rushi Sangani. All rights reserved.
//

import Observation
import BiometricAuthentication

@MainActor
@Observable
final class LoginViewModel {

    struct AlertItem {
        let title: String
        let message: String
        var showsSettings = false
    }

    // MARK: - Properties

    var username = ""
    var password = ""
    var alert: AlertItem?
    var focusUsername = false

    // Localized messages are looked up in the "Localizable" table of the main bundle.
    // Set AllowableReuseDuration in seconds to bypass the authentication when user has just unlocked the device with biometric
    @ObservationIgnored
    private let authenticator: BiometricAuthenticator = {
        let authenticator = BiometricAuthenticator(bundle: .main, tableName: "Localizable")
        authenticator.allowableReuseDuration = 30
        return authenticator
    }()

    // biometry type of this device, shown on the login button
    let biometricButtonTitle: String
    let biometricButtonImage: String

    init() {
        if authenticator.isFaceIDDevice() {
            (biometricButtonTitle, biometricButtonImage) = ("Login with Face ID", "faceid")
        } else if authenticator.isOpticIDDevice() {
            (biometricButtonTitle, biometricButtonImage) = ("Login with Optic ID", "opticid")
        } else {
            (biometricButtonTitle, biometricButtonImage) = ("Login with Touch ID", "touchid")
        }
    }

    // MARK: - Actions

    func login() {
        showLoginSuccessAlert()
    }

    func authenticateWithBiometrics() async {
        do {
            try await authenticator.authenticateWithBiometrics(reason: "", fallbackTitle: "Enter Credentials")

            // authentication successful
            showLoginSuccessAlert()
        } catch let error as AuthenticationError {
            handle(error)
        } catch {
            showErrorAlert(message: AuthenticationError.other.message(using: authenticator))
        }
    }

    // show passcode authentication
    private func authenticateWithPasscode(message: String) async {
        do {
            try await authenticator.authenticateWithPasscode(reason: message)
            showLoginSuccessAlert() // passcode authentication success
        } catch let error as AuthenticationError {
            let message = error.message(using: authenticator)
            if !message.isEmpty { showErrorAlert(message: message) }
        } catch {
            showErrorAlert(message: AuthenticationError.other.message(using: authenticator))
        }
    }

    // handle biometric authentication error
    private func handle(_ error: AuthenticationError) {
        let message = error.message(using: authenticator)

        switch error {

        // device does not support biometric (face id or touch id) authentication
        case .biometryNotAvailable:
            showErrorAlert(message: message)

        // No biometry enrolled or passcode not set in this device, ask user to update settings
        case .biometryNotEnrolled, .passcodeNotSet:
            alert = AlertItem(title: "Error", message: message, showsSettings: true)

        // show alternatives on fallback button clicked
        case .fallback:
            focusUsername = true // enter username password manually

        // Biometry is locked out now, because there were too many failed attempts.
        // Need to enter device passcode to unlock.
        case .biometryLockedout:
            Task { await authenticateWithPasscode(message: message) }

        // do nothing on canceled by system, user or app
        case .canceledBySystem, .canceledByUser, .canceledByApp:
            break

        // show error for any other reason
        default:
            showErrorAlert(message: message)
        }
    }

    // MARK: - Alerts

    private func showLoginSuccessAlert() {
        alert = AlertItem(title: "Success", message: "Login successful")
    }

    private func showErrorAlert(message: String) {
        alert = AlertItem(title: "Error", message: message)
    }
}

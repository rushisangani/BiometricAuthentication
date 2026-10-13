//
//  ViewController.swift
//  UIKit
//
//  Created by Rushi on 28/10/17.
//  Copyright © 2018 Rushi Sangani. All rights reserved.
//

import UIKit
import BiometricAuthentication

class ViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var biometricButton: UIButton!

    // MARK: - Properties

    // Localized messages are looked up in the "Localizable" table of the main bundle.
    // Set AllowableReuseDuration in seconds to bypass the authentication when user has just unlocked the device with biometric
    private let authenticator: BiometricAuthenticator = {
        let authenticator = BiometricAuthenticator(bundle: .main, tableName: "Localizable")
        authenticator.allowableReuseDuration = 30
        return authenticator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBiometricButton()
    }

    // MARK: - Actions

    @IBAction func loginButtonClicked(_ sender: Any) {
        view.endEditing(true)

        // show success alert
        showLoginSuccessAlert()
    }

    @IBAction func biometricAuthenticationClicked(_ sender: Any) {
        view.endEditing(true)

        // start authentication
        Task {
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
    }

    // MARK: - Authentication

    // show the biometry type of this device on the button
    private func configureBiometricButton() {
        let (title, image): (String, String)
        if authenticator.isFaceIDDevice() {
            (title, image) = ("Login with Face ID", "faceid")
        } else if authenticator.isOpticIDDevice() {
            (title, image) = ("Login with Optic ID", "opticid")
        } else {
            (title, image) = ("Login with Touch ID", "touchid")
        }
        biometricButton.setTitle(title, for: .normal)
        biometricButton.setImage(UIImage(systemName: image), for: .normal)
    }

    // show passcode authentication
    private func showPasscodeAuthentication(message: String) {
        Task {
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
            showGoToSettingsAlert(message: message)

        // show alternatives on fallback button clicked
        case .fallback:
            txtUsername.becomeFirstResponder() // enter username password manually

        // Biometry is locked out now, because there were too many failed attempts.
        // Need to enter device passcode to unlock.
        case .biometryLockedout:
            showPasscodeAuthentication(message: message)

        // do nothing on canceled by system, user or app
        case .canceledBySystem, .canceledByUser, .canceledByApp:
            break

        // show error for any other reason
        default:
            showErrorAlert(message: message)
        }
    }
}

// MARK: - Alerts

private extension ViewController {

    func showAlert(title: String, message: String, actions: [UIAlertAction] = [UIAlertAction(title: "OK", style: .default)]) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach(alertController.addAction)
        present(alertController, animated: true)
    }

    func showLoginSuccessAlert() {
        showAlert(title: "Success", message: "Login successful")
    }

    func showErrorAlert(message: String) {
        showAlert(title: "Error", message: message)
    }

    func showGoToSettingsAlert(message: String) {
        let settingsAction = UIAlertAction(title: "Go to settings", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
        showAlert(title: "Error", message: message, actions: [settingsAction, UIAlertAction(title: "Cancel", style: .cancel)])
    }
}

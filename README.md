# BiometricAuthentication
Use Apple FaceID or TouchID authentication in your app using BiometricAuthentication.
It's very simple and easy to use that handles Touch ID and Face ID authentication based on the device.

**Note:** - Face ID authentication requires user's persmission to be add in info.plist.
```swift
<key>NSFaceIDUsageDescription</key>
<string>This app requires Face ID permission to authenticate using Face recognition.</string>
```

![Alt text](/Images/image1.png?raw=true "Authenticate")
![Alt text](/Images/image2.png?raw=true "Fallback title")
![Alt text](/Images/image3.png?raw=true "Locked out")

## Features

- Works with Apple Face ID (iPhone X) and other Touch ID having devices.
- Predefined error handling when recognition fails.
- Automatic authentication with device passcode on multiple failed attempts.

## Requirements

- iOS 9.0+
- Xcode 8+
- Swift 3.0+

## Installation

### CocoaPods

```ruby
pod 'BiometricAuthentication'
```

## Usage

### Authenticate with biometric

```swift
BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
    // authentication success

}) { (error) in

    // error
    print(error.message())
}
```
- When reason specified as empty - default will be used based on the device. Ex. for iPhone X - **"Confirm your face to authenticate."**,  For other devices - **"Confirm your fingerprint to authenticate."**

### Can Authenticate with biometric

- Alternatively you can check before authentication by following. This will check that if device supports Touch ID or Face ID authentication and your app can use that as of now.

```swift
if BioMetricAuthenticator.canAuthenticate() {

    BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
        // authentication success

    }) { (error) in

        // error
        print(error.message())
    }
}
```
### Check for Face ID
- Check if device supports face recognition or not.
```swift
if BioMetricAuthenticator.shared.faceIDAvailable() {
    // device supports face id recognition.
}
```

### Fallback Reason
- Fallback reason title will be shown when first authentication attempt is failed.
- You can give alternate authentication options like enter 'username & password' when user clicks on fallback button.
- Default reason is empty, which will hide fallback button.

```swift
BioMetricAuthenticator.authenticateWithBioMetrics(reason: "Biometric Authentication", fallbackTitle: "Enter Credentails", success: {

    // authentication successful

}) { (error) in

    // show alternatives on fallback button clicked
    // for ex. - enter username/email and password
    if error == .fallback {
    
    }
}
```

### BiometryLockedout
- When biometry authentication is locked out after multiple failed attempts. You can unlock it by passcode authentication.
- Provide your own passcode authentication reason here, default will be used if not provided.

```swift
BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {
    // passcode authentication success

}) { (error) in
    print(error.message())
}
```

### Error Handling
- There are various cases when biometric authentication can be failed.

1. **fallback**
    - Called when user clicks on provided fallback button.
2. **biometryNotEnrolled**
    - Called when no fingerprints or face is registered with the device.
    - You can show message to register a new face or fingerprint here.
    - Default message will be shown if not provided.
3. **canceledByUser**
    - Called when authentication canceled by user.
4. **canceledBySystem**
    - Called when authentication canceled by system when app goes into background or any other reason.
5. **passcodeNotSet**
    - Called when device passcode is not set and trying to use biometry authentication.
    - We can ask user to set device passcode here by opening Settings Application.
6. **failed**
    - Called when multiple failed attempts made by user.
    - You can show error message to user here.
    - Default message can be shown if not provided.
7. **biometryLockedout**
    - Called when more than 5 failed attempts made using biometric authentication. This will locked your biometry system.
    - You'll restrict user when this error is occured.
    - Aleternatively you can ask user to enter device passcode to unlock biometry.

### Example

```swift
BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {

    // authentication successful

}, failure: { [weak self] (error) in

    // do nothing on canceled
    if error == .canceledByUser || error == .canceledBySystem {
        return
    }

    // show alternatives on fallback button clicked
    else if error == .fallback {

        // here we're entering username and password
        self?.txtUsername.becomeFirstResponder()
    }

    // No biometry enrolled in this device, ask user to register fingerprint or face
    else if error == .biometryNotEnrolled {
        self?.showGotoSettingsAlert(message: error.message())
    }

    // Biometry is locked out now, because there were too many failed attempts.
    // Need to enter device passcode to unlock.
    else if error == .biometryLockedout {
        // show passcode authentication
    }

    // show error on authentication failed
    else {
        self?.showErrorAlert(message: error.message())
    }
})
```
See [Example](https://github.com/rushisangani/BiometricAuthentication/tree/master/BiometricAuthenticationExample) for more details.

## License

BiometricAuthentication is released under the MIT license. [See LICENSE](https://github.com/rushisangani/BiometricAuthentication/blob/master/LICENSE) for details.


Pod::Spec.new do |s|

s.name         = "BiometricAuthentication"
s.version      = "4.1.0"

s.summary      = "Use Apple Face ID, Touch ID or Optic ID authentication in your app using BiometricAuthentication."

s.description  = <<-DESC
BiometricAuthentication is very simple and easy to use that handles Face ID, Touch ID, Optic ID and device passcode authentication based on the device, with async/await support and localizable messages.
                DESC

s.homepage     = "https://github.com/rushisangani/BiometricAuthentication"
s.screenshots  = "https://raw.githubusercontent.com/rushisangani/BiometricAuthentication/master/Images/image1.png", "https://raw.githubusercontent.com/rushisangani/BiometricAuthentication/master/Images/image2.png", "https://raw.githubusercontent.com/rushisangani/BiometricAuthentication/master/Images/image3.png"

s.license      = { :type => "MIT", :file => "LICENSE" }

s.author       = { "Rushi Sangani" => "rushisangani@gmail.com" }
s.source       = { :git => "https://github.com/rushisangani/BiometricAuthentication.git", :tag => "v#{s.version}" }

s.ios.deployment_target = '15.0'
s.source_files = "Sources/BiometricAuthentication/**/*.swift"
s.resource_bundles = { "BiometricAuthentication_Privacy" => ["Sources/BiometricAuthentication/PrivacyInfo.xcprivacy"] }
s.frameworks = "LocalAuthentication"

s.requires_arc = true
s.swift_versions = ["5.9", "6.0"]

end


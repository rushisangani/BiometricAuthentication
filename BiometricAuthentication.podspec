Pod::Spec.new do |s|

s.name         = "BiometricAuthentication"
s.version      = "3.0"

s.summary      = "Use Apple FaceID or TouchID authentication in your app using BiometricAuthentication."

s.description  = <<-DESC
BiometricAuthentication is very simple and easy to use that handles Touch ID and Face ID authentication based on the device.
                DESC

s.homepage     = "https://github.com/rushisangani/BiometricAuthentication"
s.screenshots  = "https://raw.githubusercontent.com/rushisangani/BiometricAuthentication/master/Images/image1.png", "https://raw.githubusercontent.com/rushisangani/BiometricAuthentication/master/Images/image2.png", "https://raw.githubusercontent.com/rushisangani/BiometricAuthentication/master/Images/image3.png"

s.license      = { :type => "MIT", :file => "LICENSE" }

s.author       = { "Rushi Sangani" => "rushisangani@gmail.com" }
s.source       = { :git => "https://github.com/rushisangani/BiometricAuthentication.git", :tag => s.version }

s.ios.deployment_target = '8.0'
s.source_files = "BiometricAuthentication/**/*.swift"

s.requires_arc = true
s.pod_target_xcconfig = { "SWIFT_VERSION" => "5.0" }

end


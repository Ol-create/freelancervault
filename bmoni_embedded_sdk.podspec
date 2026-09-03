require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "bmoni_embedded_sdk"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = "https://github.com/bmoni/bmoni_embedded_sdk"
  s.license      = package["license"]
  s.authors      = "BMONI"
  s.platforms    = { :ios => "15.1" }
  s.source       = { :git => "https://github.com/bmoni/bmoni_embedded_sdk.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"
  s.swift_version = "5.0"

  # s.dependency "BMONISigner" # native iOS SDK (Secure Enclave), once published

  install_modules_dependencies(s)
end

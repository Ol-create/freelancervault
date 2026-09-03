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

  # CryptoKit has no secp256k1 support (P-256/P-384/P-521/Curve25519 only), so
  # key generation and recoverable ECDSA signing use libsecp256k1 (the same
  # library Bitcoin Core itself uses) via this Swift wrapper.
  s.dependency "secp256k1.swift", "~> 0.10.0"
  # CryptoKit also has no Keccak-256 (only NIST SHA-3, a different padding) —
  # CryptoSwift provides the Keccak variant EIP-191/ecrecover requires.
  s.dependency "CryptoSwift", "~> 1.8"

  install_modules_dependencies(s)
end

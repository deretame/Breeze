Pod::Spec.new do |s|
  s.name             = 'coreml_upscale'
  s.version          = '0.0.1'
  s.summary          = 'CoreML image super-resolution plugin'
  s.description      = <<-DESC
A Flutter plugin for CoreML-based image super-resolution on macOS and iOS.
                       DESC
  s.homepage         = 'https://github.com/your_name/coreml_upscale'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Breeze' => 'breeze@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint msb_ekyc_face_detect_camera.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'msb_ekyc_face_detect_camera'
  s.version          = '1.0.0'
  s.summary          = 'Android and IOS support for ekyc library'
  s.description      = <<-DESC
Android and IOS support for ekyc library
                       DESC
  s.homepage         = 'http://msb.com.vn'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'MSB' => 'support@msb.com.vn' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'GoogleMLKit/TextRecognition'
  s.static_framework = true
  s.vendored_frameworks = ['eKYC.framework']
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' , 'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/GoogleMLKit/MLKitCore' }
  s.swift_version = '5.0'
end

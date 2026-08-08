#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint native_download_manager.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'native_download_manager'
  s.version          = '1.0.5'
  s.summary          = 'A production-ready Flutter package providing native background download capability for Android and iOS.'
  s.description      = <<-DESC
A production-ready Flutter package providing native background download capability for Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/adityaku/native_download_manager'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Aditya' => 'aditya@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'native_download_manager_privacy' => ['Classes/PrivacyInfo.xcprivacy']}
end


#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint banana_player.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'banana_player'
  s.version          = '0.0.1'
  s.summary          = 'A exoplayer wrapper library for your flutter projects'
  s.description      = <<-DESC
A exoplayer wrapper library for your flutter projects
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'banana_player/Sources/banana_player/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'banana_player_privacy' => ['banana_player/Sources/banana_player/PrivacyInfo.xcprivacy']}
end

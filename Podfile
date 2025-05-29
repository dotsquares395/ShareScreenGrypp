use_frameworks!
target 'ShareScreenGrypp' do
  pod 'OTXCFramework', :modular_headers => true
end
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
      config.build_settings['MACH_O_TYPE'] = 'staticlib'
    end
  end
end

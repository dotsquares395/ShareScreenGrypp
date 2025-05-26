use_frameworks!
target 'GryppSDk' do
  pod 'OTXCFramework', :modular_headers => true
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'GryppSDk'
      target.build_configurations.each do |config|
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
    end
  end
end

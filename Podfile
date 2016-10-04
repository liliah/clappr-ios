platform :ios, '8.4'
source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

project 'Clappr.xcodeproj'

target 'Clappr_Tests' do
  pod 'Quick', '~> 0.10'
  pod 'Nimble', '~> 5.0.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end

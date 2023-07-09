# Uncomment the next line to define a global platform for your project
# platform :ios, '10.3'

target 'Musicos' do
  use_frameworks!
  pod 'SwipeMenuViewController'
#  pod 'SwiftyJSON', '~> 4.0'
  pod 'ReactiveSwift'
  # pod 'YoutubeEngine', '~> 0.3'
  # pod "YoutubeEngine", :git => 'https://github.com/Igor-Palaguta/YoutubeEngine', :tag => '0.7.0'
  pod 'AudioKit/Core', '~> 4.0'
  pod 'RealmSwift'
  #pod 'ChameleonFramework/Swift'
  pod 'SwipeCellKit'
  pod 'Kingfisher'
  pod 'Tabman', '~> 2.9'

  pod 'Firebase/Auth'	
	pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'CodableFirebase'
  
  pod 'AlgoliaSearchClient', '~> 8.0'
  
  pod "XCDYouTubeKit", "~> 2.15"
  pod 'PopupDialog', '~> 1.1'
  pod 'KeychainAccess'
  pod 'SimpleCheckbox'
  
  # pod 'SVProgressHUD'
  # pod 'SDWebImage', '~> 4.0'
end

post_install do |installer|
     installer.pods_project.targets.each do |target|
           target.build_configurations.each do |config|
                 config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
           end
     end
 end

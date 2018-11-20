project 'Dash/Dash iOS.xcodeproj'
platform :ios, '9.0'
inhibit_all_warnings!

target 'Dash' do
  pod 'AutoCoding'
  pod 'DZNEmptyDataSet', git: 'https://github.com/benrudhart/DZNEmptyDataSet.git'
  pod 'FMDB/standalone-fts'
  pod 'GZIP'
  pod 'JGMethodSwizzler'
  pod 'NSTimer-Blocks'
  pod 'Reachability'
  pod 'SAMKeychain'
  pod 'UIActionSheet+Blocks'
  pod 'UIAlertView+Blocks'

  # Commented out a bunch of stuff in MRBlurView's redraw, otherwise the overlay
  # progress makes the entire screen flicker when it is first shown.
  # MRStopButton has support for whole sizes (their calculations ended up with
  # non-integral frames). Also overwrote pointInside: for MRCircularProgressView
  # Removed AccessibilityValueChangeNotify because it causes VoiceOver to stall.
  pod 'MRProgress', path: 'Modified Pods/MRProgress/MRProgress.podspec'

  # Modified to make addChild: remove parent
  pod 'KissXML', path: 'Modified Pods/KissXML-5.1.2/KissXML.podspec'

  # Modified to add originating IP address support to DTBonjourDataConnection
  # Also modified to send a delegate message when a connection closes
  # Replaced asserts() with ifs() in DTBonjourServer start
  pod 'DTBonjour', path: 'Modified Pods/DTBonjour/DTBonjour.podspec'

  target 'Dash App Store' do
    pod 'HockeySDK'
  end
end

post_install do |_installer|
  require 'fileutils'
  plist_source = 'Pods/Target Support Files/Pods-Dash/Pods-Dash-acknowledgements.plist'
  plist_destination = 'Dash/Settings.bundle/Cocoa_Pods_Acknowledgements.plist'
  FileUtils.cp_r(plist_source, plist_destination, remove_destination: true)
end

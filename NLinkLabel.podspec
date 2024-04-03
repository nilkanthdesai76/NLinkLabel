#
# Be sure to run `pod lib lint NLinkLabel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NLinkLabel'
  s.version          = '0.1.0'
  s.summary          = 'A UILabel extension for adding tappable sections to text, enhancing interactivity within iOS apps.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.homepage         = 'https://github.com/nilkanthdesai76/NLinkLabel'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'nilkanthdesai76' => 'nilkanthdesai76@gmail.com' }
  s.source           = { :http => 'https://github.com/nilkanthdesai76/NLinkLabel.git' }
  s.swift_versions    = ['4.2', '5.0']
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '14.0'

  #s.source_files     = 'Pod/Classes/**/*.{h,m,swift}'
  s.source_files = 'NLinkLabel/Classes/**/*.{h,m,swift}'
  
  # s.resource_bundles = {
  #   'NLinkLabel' => ['NLinkLabel/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

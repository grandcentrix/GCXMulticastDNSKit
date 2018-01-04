Pod::Spec.new do |spec|
  spec.name = "GCXMulticastDNSKit"
  spec.version = "1.2.0"
  spec.summary = "mDNS discovery framework for iOS."
  spec.homepage = "https://www.grandcentrix.net"
  spec.license =  { :type => 'Apache License, Version 2.0',  :file => 'LICENSE.txt' }
  spec.authors = { "Christian Netthöfel" => 'christian.netthoefel@grandcentrix.net' }
  spec.social_media_url = "http://twitter.com/grandcentrix"
  spec.platform = :ios, "9.0"
  spec.source = { git: "https://github.com/grandcentrix/GCXMulticastDNSKit.git", tag: "v#{spec.version}"}
  spec.source_files = "GCXMulticastDNSKit/**/*.{swift}"
end

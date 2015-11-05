Pod::Spec.new do |s|
  s.name         = "AMYServer"
  s.version      = "2.1.1"
  s.summary      = "AMY Mocks Your Server - A mock HTTP server for KIF."
  s.homepage     = "https://github.com/kif-framework/AMYServer"
  s.license      = 'Apache 2.0'
  s.author       = { "Brian Nickel" => "brian.nickel@gmail.com" }
  s.source       = { :git => "https://github.com/kif-framework/AMYServer.git", :tag => "v2.1.1" }
  s.platform     = :ios, '5.1'
  s.requires_arc = true
  s.source_files = 'AMYServer'
  s.dependency     'GRMustache', '~> 7.0'
  s.dependency     'KIF', '~> 3.0'
  s.framework    = 'XCTest'
end

Pod::Spec.new do |s|
  s.name         = "AMYServer"
  s.version      = "2.0.0"
  s.summary      = "AMY Mocks Your Server - A mock HTTP server for KIF."
  s.homepage     = "https://github.com/bnickel/AMYServer"
  s.license      = 'Apache 2.0'
  s.author       = { "Brian Nickel" => "brian.nickel@gmail.com" }
  s.source       = { :git => "https://github.com/bnickel/AMYServer.git", :tag => "v2.0.0" }
  s.platform     = :ios, '5.1'
  s.requires_arc = true
  s.dependency 'GRMustache', '~> 7.0'

  s.default_subspec = 'XCTest'

  s.subspec 'OCUnit' do |sentest|
    sentest.source_files = 'AMYServer'
    sentest.dependency 'KIF/OCUnit', '~> 3.0'

    # I would expect the following to be inherited but lint disagrees.
    sentest.framework = 'SenTestingKit'
    sentest.xcconfig = { 'OTHER_CFLAGS' => '-DKIF_SENTEST' }
  end

  s.subspec 'XCTest' do |xctest|
    xctest.source_files = 'AMYServer'
    xctest.dependency 'KIF/XCTest', '~> 3.0'

    # I would expect the following to be inherited but lint disagrees.
    xctest.framework = 'XCTest'
    xctest.xcconfig = { 'OTHER_CFLAGS' => '-DKIF_XCTEST' }
  end
end

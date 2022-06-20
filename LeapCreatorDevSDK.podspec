Pod::Spec.new do |s|
    s.name         = "LeapCreatorDevSDK"
    s.version      = "0.1.9"
    s.summary      = "Product engagement made easy"
    s.description  = <<-DESC 
    Product engagement made easy. Onboard, nudge, & delight your mobile users
                     DESC
    s.homepage     = "https://leap.is"
    s.platform	   = :ios, "10.0"
    s.swift_versions = ['5.0']
    s.license      = { :type => "BSD",:file=>"LICENSE.md"}
    s.author       = { "Ajay S" => "ajay@jiny.io" }
    s.source       = { :git => "https://github.com/Leap-Platform/leap-creator-dev.git", :tag => s.version.to_s }
    s.vendored_frameworks = "LeapCreatorSDK.xcframework"
    s.frameworks   = 'UIKit', 'Webkit'
  end

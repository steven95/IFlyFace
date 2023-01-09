    Pod::Spec.new do |s|
    
      s.name         = "IFlyFace"

      s.version      = "1.2.3"

      s.summary      = "A short description of tcggMain."

      s.description  = "Good"
    
      s.homepage     = "https://github.com/steven95/"

      s.license      = "MIT"

      s.author       = { "Jusive" => "1345266022@qq.com" }

      s.source      = { :git => "https://github.com/steven95/IFlyFace.git", :tag => "#{s.version}" }
 
      s.dependency  'SVProgressHUD'
      
      s.static_framework = true
      
      s.source_files  = "Utility/*/*{.h,.m,.xml,.mm}"
      
      s.vendored_frameworks = 'Utility/*.framework'
      
      s.vendored_libraries = 'Utility/*.a'
      
      s.libraries = 'z','c++.1'
      
      s.xcconfig = {'LIBRARY_SEARCH_PATHS' => ["\"$(PODS_ROOT)/iflyMSC/**\""]}
      
      s.requires_arc = true # 基于ARC
      
      s.frameworks = 'UIKit','Foundation','AVFoundation','SystemConfiguration','CoreTelephony','AudioToolbox','CoreLocation','AddressBook','CoreGraphics'
      
      s.resources =  "Utility/JusiveIFlyFace.bundle"
      
    end


Pod::Spec.new do |spec|

  spec.name         = "ShareScreenGrypp"
  spec.version      = "1.1.2"
  spec.summary      = "I've developed a custom SDK that enables the user's app screen to be displayed on the web-based PlayConsole."
  spec.description  = "I’ve developed a custom SDK to share a user’s app screen with a web-based PlayConsole. It supports session control, marker drawing, and real-time agent cursor visibility for interactive support and collaboration between users and agents."
  spec.homepage     = "https://github.com/dotsquares395/ShareScreenGrypp"
  spec.license      = {:type => "MIT", :file => "LICENSE"}
  spec.authors      = { "dotsquares395" => "rohan.sharma@dotsquares.com" }
  spec.platform     = :ios, "15.0"
  spec.source       = {:git => "https://github.com/dotsquares395/ShareScreenGrypp.git", :tag => spec.version}
  spec.source_files =  'ShareScreenGrypp/*.{swift}'
  spec.public_header_files = 'ShareScreenGrypp/ShareScreenGrypp/ShareScreenGrypp.h'
  spec.ios.deployment_target = '15.0'
  spec.requires_arc = true
  spec.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }
  spec.dependency 'OpenTok', '~> 2.0'  # Verify the correct version
  spec.static_framework = true
  
end


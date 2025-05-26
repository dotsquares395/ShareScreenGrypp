
Pod::Spec.new do |spec|

  spec.name         = "ShareScreenGrypp"
  spec.version      = "1.0.0"
  spec.summary      = "I've developed a custom SDK that enables the user's app screen to be displayed on the web-based PlayConsole."
  spec.description  = "I’ve developed a custom SDK to share a user’s app screen with a web-based PlayConsole. It supports session control, marker drawing, and real-time agent cursor visibility for interactive support and collaboration between users and agents."
  spec.homepage     = "https://github.com/dotsquares395/ShareScreenGrypp"
  spec.license      =  "MIT"
  spec.authors      = { "dotsquares395" => "rohan.sharma@dotsquares.com" }
  spec.platform     = :ios, "15.0"
  spec.source       = {:git => "https://github.com/dotsquares395/ShareScreenGrypp.git", :tag => spec.version}
  spec.source_files =  'ShareScreenGrypp/Document/*.{swift}'
  spec.swift_versions = '5.0'
  
end


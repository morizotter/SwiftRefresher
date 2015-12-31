Pod::Spec.new do |s|
  s.name         = "SwiftRefresher"
  s.version      = "0.9.0"
  s.summary      = "SwiftRefresher is one of the alternatives of UIRefreshControl."
  s.description  = <<-DESC
                    - Simple and easy to use.
                    - Customize loading view whatever you want.
                   DESC

  s.homepage     = "https://github.com/morizotter/SwiftRefresher"
  s.screenshots  = "https://raw.githubusercontent.com/morizotter/SwiftRefresher/master/refresher.gif"
  s.license      = "MIT"
  s.author             = { "Morita Naoki" => "namorit@gmail.com" }
  s.platform     = :ios
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/morizotter/SwiftRefresher.git", :tag => "0.9.0" }
  s.source_files  = "SwiftRefresher/**/*.swift"
  s.resources = "SwiftRefresher/Resources/*.png"
  s.requires_arc = true
end

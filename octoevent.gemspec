Gem::Specification.new do |s|
  s.name              = "octoevent"
  s.version           = "0.1.4"
  s.date              = "2013-05-18"
  s.summary           = "Grab activity events for you from Octocat"
  s.homepage          = "https://github.com/void-main/OctoEvent"
  s.email             = "voidmain1313113@gmail.com"
  s.authors           = ["Peng Sun"]
  s.has_rdoc          = true
  s.require_path      = "lib"
  s.files             = %w( README.md LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.add_development_dependency 'httpclient', '~> 2.3.3'
  s.add_runtime_dependency 'httpclient', '~> 2.3.3'
  s.description       = <<-desc
  Grab activity events for you from Octocat
  desc
end

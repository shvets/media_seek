# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'media_seek/version'

Gem::Specification.new do |spec|
  spec.name          = "media_seek"
  spec.version       = MediaSeek::VERSION
  spec.authors       = ["Alexander Shvets"]
  spec.email         = "alexander.shvets@gmail.com"

  spec.summary       = %q{Summary: Search for media.}
  spec.description   = %q{Search for media.}
  spec.homepage      = "http://github.com/shvets/media_seek"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  
  spec.add_runtime_dependency "json_pure", ["~> 1.8"]
  spec.add_runtime_dependency "resource_accessor", ["~> 1.2"]
  spec.add_runtime_dependency "nokogiri", [">= 1.6.8", "~> 1.6"]
  spec.add_runtime_dependency "ruby-progressbar", [">= 1.8.1", "~> 1.8"]
  spec.add_runtime_dependency "highline", [">= 1.7.8", "~> 1.7"]
  spec.add_development_dependency "gemspec_deps_gen", ["~> 1.1"]
  spec.add_development_dependency "gemcutter", ["~> 0.7"]
  spec.add_development_dependency "thor", ["~> 0.19"]

end





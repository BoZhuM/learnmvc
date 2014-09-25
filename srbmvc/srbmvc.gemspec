# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'srbmvc/version'

Gem::Specification.new do |spec|
  spec.name          = "srbmvc"
  spec.version       = Srbmvc::VERSION
  spec.authors       = ["suffering"]
  spec.email         = ["zhuboliu@gmail.com"]
  spec.summary       = %q{simple ruby mvc app}
  spec.description   = %q{just a tutorial demo, how to rebuild rails}
  spec.homepage      = "https://github.com/suffering/learnmvc"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "rack"
  spec.add_runtime_dependency "rspec"
  spec.add_runtime_dependency "tilt"
  spec.add_runtime_dependency "activerecord"
  spec.add_runtime_dependency "activesupport"
end

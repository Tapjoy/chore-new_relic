# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chore/new_relic/version'

Gem::Specification.new do |spec|
  spec.name          = "chore-new_relic"
  spec.version       = Chore::NewRelic::VERSION
  spec.authors       = ["Tapjoy"]
  spec.email         = ["eng-group-arch@tapjoy.com"]
  spec.summary       = "NewRelic integration for chore"
  spec.description   = "A repository for NewRelic integrations"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency("chore-core", [">= 1.8.4"])
  spec.add_development_dependency("bundler", [">= 0"])
  spec.add_development_dependency("rake")
  spec.add_runtime_dependency(%q<newrelic_rpm>, ['>= 9.2.0'])
end

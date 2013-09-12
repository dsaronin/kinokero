# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kinokero/version'

Gem::Specification.new do |spec|
  spec.name          = "kinokero"
  spec.version       = Kinokero::VERSION
  spec.authors       = ["daudi amani"]
  spec.email         = ["dsaronin@gmail.com"]
  spec.description   = %q{faraday-based http client for interacting with Google CloudPrint &amp; other }
  spec.summary       = %q{faraday-based http client for interacting with Google CloudPrint &amp; other }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday_middleware'
  spec.add_dependency 'simple_oauth'
  spec.add_dependency 'hashie'
  spec.add_dependency 'typhoeus'
  spec.add_dependency 'logger'

end

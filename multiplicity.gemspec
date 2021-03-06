# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'multiplicity/version'

Gem::Specification.new do |spec|
  spec.name          = "multiplicity"
  spec.version       = Multiplicity::VERSION
  spec.authors       = ["Adam Lassek"]
  spec.email         = ["adam@doubleprime.net"]

  spec.summary       = %q{Simple multitenancy for rack-based web servers}
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'virtus', '>= 1.0.5'
  spec.add_dependency 'rack'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-expectations"
end

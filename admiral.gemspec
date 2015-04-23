# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'admiral/version'

Gem::Specification.new do |spec|
  spec.name          = "admiral"
  spec.version       = Admiral::VERSION
  spec.authors       = ["Peter T. Brown"]
  spec.email         = ["p@ptb.io"]
  spec.description   = %q{A command line tool for wielding cloudformation templates.}
  spec.summary       = %q{A command line tool for wielding cloudformation templates.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency 'thor', '~> 0.19'

end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bamboo_util/version'

Gem::Specification.new do |spec|
  spec.name          = "bamboo_util"
  spec.version       = BambooUtil::VERSION
  spec.authors       = ["Wang, Dawei"]
  spec.email         = ["daweiwang.gatekeeper@gmail.com"]
  spec.summary       = %q{Invoke remote bamboo task}
  spec.description   = %q{Invoking remote bamboo task with REST api}
  spec.homepage      = ""
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rake", "> 10.0"
  spec.add_dependency "rest-client"
  spec.add_development_dependency "bundler", "~> 1.7"
  
end

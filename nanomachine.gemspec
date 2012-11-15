# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "nanomachine/version"

Gem::Specification.new do |gem|
  gem.name          = "nanomachine"
  gem.summary       = "A really tiny state machine for ruby. No events, only acceptable transitions and transition callbacks."

  gem.version       = Nanomachine::VERSION

  gem.homepage      = "https://github.com/elabs/nanomachine"
  gem.authors       = ["Ivan Navarrete", "Kim Burgestrand"]
  gem.email         = ["crzivn@gmail.com", "kim@burgestrand.se"]
  gem.license       = "MIT License"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 2.0"
end

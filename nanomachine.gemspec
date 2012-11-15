# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nanomachine/version'

Gem::Specification.new do |gem|
  gem.name          = "nanomachine"
  gem.version       = Nanomachine::VERSION
  gem.authors       = ["Ivan Navarrete and Kim Burgestrand"]
  gem.email         = ["dev+ivannavarrete+burgestrand@elabs.se"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end

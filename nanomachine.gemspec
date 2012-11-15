# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "nanomachine/version"

Gem::Specification.new do |gem|
  gem.name          = "nanomachine"
  gem.summary       = "A really tiny state machine for ruby. No events, only acceptable transitions and transition callbacks."
  gem.description   = <<-DESCRIPTION.gsub(/^ */, "")
    A really tiny state machine for ruby. No events, only accepted transitions and transition callbacks.
    The difference between Nanomachine and Micromachine is that Micromachine transitions to new states
    in response to events; multiple events can transition between the two same states. Nanomachine, on
    the other hand, does not care about events, and only needs the state you want to be in after successful
    transition.

    Nanomachine can be used in any ruby project, and have no runtime dependencies.

    Example:
      state_machine = Nanomachine.new("unpublished") do |fsm|
        fsm.transition("published", %w[unpublished processing removed])
        fsm.transition("unpublished", %w[published processing removed])
        fsm.transition("processing", %w[published unpublished])
        fsm.transition("removed", []) # defined for being explicit

        fsm.on_transition do |(from_state, to_state)|
          update_column(:state, to_state)
        end
      end

      if state_machine.transition_to("published")
        puts "Publish success!"
      else
        puts "Publish failure! We’re in \#{state_machine.state}."
      end
  DESCRIPTION

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

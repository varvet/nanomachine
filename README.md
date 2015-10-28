# Nanomachine

[![Build Status](https://travis-ci.org/elabs/nanomachine.svg?branch=master)](http://travis-ci.org/elabs/nanomachine)

A really tiny state machine for ruby. No events, only accepted transitions and transition callbacks.

The difference between Nanomachine, and otherwise known Micromachine (https://rubygems.org/gems/micromachine) is that
Micromachine transitions to new states in response to events; multiple events can transition between the two same states.
Nanomachine, on the other hand, does not care about events, and only needs the state you want to be in after successful
transition.

Nanomachine can be used in any ruby project, and have no runtime dependencies.

## Installation

Install the gem:

```shell
gem install nanomachine
```

or add it to your Gemfile, if you are using [Bundler][]:

```ruby
gem "nanomachine", "~> 1.0"
```

[Bundler]: http://gembundler.com/

## Example

```ruby
state_machine = Nanomachine.new("unpublished") do |fsm|
  fsm.transition("published", %w[unpublished processing removed])
  fsm.transition("unpublished", %w[published processing removed])
  fsm.transition("processing", %w[published unpublished])
  fsm.transition("removed", []) # defined for being explicit

  fsm.on_transition(:to => "processing") do |(previous_state, _), id|
    Worker.schedule(id, previous_state)
  end

  fsm.on_transition do |(from_state, to_state)|
    update_column(:state, to_state)
  end
end

if state_machine.transition_to("published")
  puts "Publish success!"
else
  puts "Publish failure! We’re in #{state_machine.state}."
end
```

## License

Copyright (c) 2012 Ivan Navarrete and Kim Burgestrand

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

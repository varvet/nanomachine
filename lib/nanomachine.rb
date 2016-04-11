require "nanomachine/version"
require "set"

# A minimal state machine where you transition between states, instead
# of transition by input symbols or events.
#
# @example
#   state_machine = Nanomachine.new("unpublished") do |fsm|
#     fsm.transition("published", %w[unpublished processing removed])
#     fsm.transition("unpublished", %w[published processing removed])
#     fsm.transition("processing", %w[published unpublished])
#     fsm.transition("removed", []) # defined for being explicit
#
#     fsm.on_transition do |(from_state, to_state)|
#       update_column(:state, to_state)
#     end
#   end
#
#   if state_machine.transition_to("published")
#     puts "Publish success!"
#   else
#     puts "Publish failure! We’re in #{state_machine.state}."
#   end
#
#
class Nanomachine
  # Raised when a transition cannot be performed.
  InvalidTransitionError = Class.new(StandardError)

  # Raised when a given state cannot be accepted.
  InvalidStateError = Class.new(StandardError)

  # Construct a Nanomachine with an initial state.
  #
  # @example initialization with a block
  #   machine = Nanomachine.new("initial") do |fsm|
  #     fsm.transition("initial", %w[green orange])
  #     fsm.transition("green", %w[orange error])
  #     fsm.transition("orange", %w[green error])
  #     # error is a dead state, no transition out of it
  #     # so not necessary to define the transitions for it
  #
  #     fsm.on_transition(to: "error") do |(from_state, to_state), message|
  #       notifier.notify_error(message)
  #     end
  #
  #     fsm.on_transition do |(from_state, to_state)|
  #       object.update_state(to_state)
  #     end
  #   end
  #
  # @param [#to_s] initial_state state the machine is in after initialization
  # @raise [InvalidStateError] if initial state is nil
  # @yield [self] yields the machine for easy definition of states
  # @yieldparam [Nanomachine] self
  def initialize(initial_state)
    @state = to_state(initial_state)
    @transitions = Hash.new(Set.new)
    @callbacks = Hash.new { |h, k| h[k] = [] }
    yield self if block_given?
  end

  # @return [String] current state of the state machine.
  attr_reader :state

  # @example
  #   {"initial"=>#<Set: {"green", "orange"}>,
  #    "green"=>#<Set: {"orange", "error"}>,
  #    "orange"=>#<Set: {"green", "error"}>}
  #
  # @return [Hash<String, Set>] mapping of state to possible transition targets
  attr_reader :transitions

  # Define possible state transitions from the source state.
  #
  # @example
  #   fsm.transition("green", %w[orange red])
  #   fsm.transition("orange", %w[red])
  #   fsm.transition(:error, [:nowhere])
  #
  # @param [#to_s] from
  # @param [#each] to each target state must respond to #to_s
  def transition(from, to)
    transitions[to_state(from)] = Set.new(to).map! { |state| to_state(state) }
  end

  # Define a callback to be executed on transition.
  #
  # @example callback executed on any transition
  #   fsm.on_transition do |(from_state, to_state), *args, &block|
  #     # executed on any transition
  #   end
  #
  # @example callback executed on transition from a given state only
  #   fsm.on_transition(from: "green") do |(from_state, to_state), *args, &block|
  #     # executed only on transitions *from* green state
  #   end
  #
  # @example callback executed on transition to a given state only
  #   fsm.on_transition(to: "green") do |(from_state, to_state), *args, &block|
  #     # executed only on transitions *to* green state
  #   end
  #
  # @example callback executed on transition between two states only
  #   fsm.on_transition(from: "green", to: "red") do |(from_state, to_state), *args, &block|
  #     # executed only on transitions between green and red
  #   end
  #
  # @param [Hash] options constraint on when callback is to be executed
  # @option options [#to_s, nil] :from (nil) only match when transitioning from the given state, nil for any
  # @option options [#to_s, nil] :to (nil) only match when transitioning to the given state, nil for any
  # @yield [transition, *args, &block] transition states (from, to), and parameters given to {#transition_to} on transition
  # @yieldparam [Array<from_state, to_state>] transition
  # @yieldparam *args arguments passed to {#transition_to}
  # @yieldparam &block block passed to {#transition_to}
  # @raise [ArgumentError] when given unknown options
  # @raise [LocalJumpError] when no callback block is supplied
  def on_transition(options = {}, &block)
    unless block_given?
      raise LocalJumpError, "no block given"
    end

    from = options.delete(:from)
    from &&= to_state(from)

    to = options.delete(:to)
    to &&= to_state(to)

    unless options.empty?
      raise ArgumentError, "unknown options: #{options.keys.join(", ")}"
    end

    @callbacks[[from, to]] << block
  end

  # Transition the state machine from the current state to a target state.
  #
  # @example transition to error state with a message given to any callbacks
  #   if previous_state = fsm.transition_to("error", "something went really wrong")
  #     puts "Transition from #{previous_state} to #{fsm.state} successful!"
  #   else
  #     puts "Transition failed."
  #   end
  #
  # @param [#to_s] other_state new state to transition to
  # @param args any number of arguments, passed to callbacks defined with {#on_transition}
  # @param block passed to callbacks defined with {#on_transition}
  # @return [String, false] state the machine was in before transition, or false if transition is not allowed
  def transition_to(other_state, *args, &block)
    if transition_to?(other_state)
      other_state = to_state(other_state)
      previous_state, @state = @state, other_state
      [[nil, nil], [previous_state, nil], [nil, other_state], [previous_state, other_state]].each do |combo|
        @callbacks[combo].each do |callback|
          callback.call([previous_state, other_state], *args, &block)
        end
      end
      previous_state
    else
      false
    end
  end

  # Same as {#transition_to}, but raises an error if the transition is not allowed.
  #
  # @example
  #   fsm.transition_to!("bogus state") # => InvalidTransitionError
  #
  # @param (see #transition_to)
  # @return [String] the state the state machine was in before transition
  # @raise [InvalidTransitionError] if the state machine cannot transition from current state to target state
  def transition_to!(other_state)
    if previous_state = transition_to(other_state)
      previous_state
    else
      raise InvalidTransitionError, "cannot transition from #{state.inspect} to #{other_state.inspect}"
    end
  end

  # Query to see if it's possible to transition to the given state.
  #
  # @example
  #   fsm.transition_to?("state") # => true
  #
  # @param (see #transition_to)
  # @return [Boolean]
  def transition_to?(other_state)
    transitions[state].include?(to_state(other_state))
  end

  private

  def to_state(state)
    if state.nil?
      raise InvalidStateError, "state cannot be nil"
    else
      state.to_s
    end
  end
end

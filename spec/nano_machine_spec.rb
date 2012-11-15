describe "Nanomachine state machine" do
  before do
    @callbacks = []
  end

  let(:fsm) do
    Nanomachine.new("A") do |m|
      m.transition("A", %w[B C E X])
      m.transition("B", %w[A])
      m.transition(:C, [:A, :D])
      m.transition("D", %w[])
      m.transition("E", %w[B C])

      m.on_transition(:to => "B") do |*args, &block|
        @callbacks << [:to, args, block]
      end

      m.on_transition(:from => "A") do |*args, &block|
        @callbacks << [:from, args, block]
      end

      m.on_transition(:from => "A", :to => "B") do |*args, &block|
        @callbacks << [:from_to, args, block]
      end

      m.on_transition(:from => "E", :to => "C") do |*args, &block|
        @callbacks << [:from_to_e, args, block]
      end

      m.on_transition do |*args, &block|
        @callbacks << [:any, args, block]
      end
    end
  end

  describe "VERSION" do
    specify { Nanomachine::VERSION.should be_a String }
  end

  describe "#initialize" do
    it "raises an error if given an invalid initial state" do
      expect { Nanomachine.new(nil) }.to raise_error(Nanomachine::InvalidStateError, /initial state/)
    end
  end

  describe "#state" do
    it "returns the current state" do
      fsm.state.should eq("A")
    end
  end

  describe "#transitions" do
    it "returns the available transitions" do
      fsm.transitions.should eq({"A" => Set.new(%w[B C E X]),
                                 "B" => Set.new(%w[A]),
                                 "C" => Set.new(%w[A D]),
                                 "D" => Set.new(),
                                 "E" => Set.new(%w[B C])})
    end
  end

  describe "#on_transition" do
    it "raises an error when given unknown options" do
      expect { fsm.on_transition(:bad_option => "foo") { } }.to raise_error(ArgumentError, /bad_option/)
    end

    it "raises an error when given no block" do
      expect { fsm.on_transition }.to raise_error(LocalJumpError, /no block given/)
    end
  end

  describe "#transition_to" do
    it "transitions to the new state" do
      expect { fsm.transition_to("B") }.to change { fsm.state }.from("A").to("B")
    end

    it "does not transition when the transition is undefined" do
      fsm.transition_to("X")
      expect { fsm.transition_to("A").should be_false }.to_not change { fsm.state }
    end

    it "returns the previous state" do
      fsm.transition_to("B").should eq("A")
    end

    it "returns false if transition failed" do
      fsm.transition_to("D").should be_false
    end

    context "callbacks" do
      it "executes all callbacks in the correct order, most generic first" do
        block = proc {}
        args = [1, [3, 4]]

        fsm.transition_to("B", *args, &block)

        @callbacks.should eq([
          [:any, [["A", "B"], 1, [3, 4]], block],
          [:from, [["A", "B"], 1, [3, 4]], block],
          [:to, [["A", "B"], 1, [3, 4]], block],
          [:from_to, [["A", "B"], 1, [3, 4]], block]
        ])
      end

      it "executes callbacks reacting to any transition" do
        fsm.transition_to("C")
        @callbacks.clear
        fsm.transition_to("D")

        @callbacks.should eq([
          [:any, [["C", "D"]], nil],
        ])
      end

      it "executes callbacks for the from-transition" do
        fsm.transition_to("C")

        @callbacks.should eq([
          [:any, [["A", "C"]], nil],
          [:from, [["A", "C"]], nil],
        ])
      end

      it "executes callbacks for the to-transition" do
        fsm.transition_to("E")
        @callbacks.clear
        fsm.transition_to("B")

        @callbacks.should eq([
          [:any, [["E", "B"]], nil],
          [:to, [["E", "B"]], nil],
        ])
      end

      it "executes callbacks for the from-to-transition" do
        fsm.transition_to("E")
        @callbacks.clear
        fsm.transition_to("C")

        @callbacks.should eq([
          [:any, [["E", "C"]], nil],
          [:from_to_e, [["E", "C"]], nil],
        ])
      end

      it "executes no callbacks on failed transitions" do
        fsm.transition_to("D").should be_false
        @callbacks.should be_empty
      end
    end
  end

  describe "#transition_to!" do
    it "raises an error on an invalid transition" do
      fsm.should_receive(:transition_to).and_return(false)
      expect { fsm.transition_to!("D") }.to raise_error(Nanomachine::InvalidTransitionError, /cannot transition/)
    end

    it "returns the previous state on success" do
      fsm.transition_to!("B").should eq "A"
    end
  end
end

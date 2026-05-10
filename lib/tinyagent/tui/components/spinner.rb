# frozen_string_literal: true

require_relative '../core/message'
require_relative '../core/commands'

module Tinyagent
  module Tui
    # Spinner component for long-running operations.
    class Spinner
      FRAMES = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'].freeze

      # @rbs @frame_index: Integer
      # @rbs @tick_interval: Float

      class TickMessage < Message; end

      # @rbs tick_interval: Float
      def initialize(tick_interval: 0.1) #: void
        @frame_index = 0
        @tick_interval = tick_interval
      end

      def view #: String
        FRAMES[@frame_index % FRAMES.length]
      end

      # @rbs message: Message
      def update(message) #: Array[untyped]
        @frame_index += 1 if message.is_a?(TickMessage)
        [self, tick]
      end

      def tick #: Commands::BatchCommand
        sleep_cmd = Commands::BatchCommand.new([])
        Commands.batch([sleep_cmd])
      end
    end
  end
end

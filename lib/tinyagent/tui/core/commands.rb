# frozen_string_literal: true

module Tinyagent
  module Tui
    # Command values used by the custom TUI runtime.
    module Commands
      # Command for enabling the terminal alternate screen buffer.
      class EnterAltScreenCommand
        ANSI_ALT_SCREEN_ON = "\e[?1049h"

        def ansi_sequence #: String
          ANSI_ALT_SCREEN_ON
        end
      end

      # Command for terminating the current TUI program.
      class QuitCommand
      end

      # Command grouping multiple commands to be executed in order.
      class BatchCommand
        attr_reader :commands #: Array[untyped]

        # @rbs commands: Array[untyped]
        def initialize(commands) #: void
          @commands = commands
        end
      end

      module_function

      def enter_alt_screen #: EnterAltScreenCommand
        EnterAltScreenCommand.new
      end

      def quit #: QuitCommand
        QuitCommand.new
      end

      # @rbs cmds: Array[untyped]
      def batch(cmds) #: BatchCommand
        BatchCommand.new(cmds)
      end
    end
  end
end

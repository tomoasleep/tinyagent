# frozen_string_literal: true

module Tinyagent
  module Tui
    # Minimal model protocol for the custom TUI runtime.
    module Model
      def init #: Array[untyped]
        [self, nil]
      end

      def update(_message) #: Array[untyped]
        [self, nil]
      end

      def view #: String
        ''
      end
    end
  end
end

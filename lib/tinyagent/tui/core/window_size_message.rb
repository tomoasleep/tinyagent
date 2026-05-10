# frozen_string_literal: true

module Tinyagent
  module Tui
    # Message carrying the current terminal dimensions.
    class WindowSizeMessage < Message
      attr_reader :width #: Integer
      attr_reader :height #: Integer

      # @rbs width: Integer
      # @rbs height: Integer
      def initialize(width:, height:) #: void
        @width = width
        @height = height
        super()
      end
    end
  end
end

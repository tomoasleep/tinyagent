# frozen_string_literal: true

require_relative 'ansi'

module Tinyagent
  module Tui
    # Scrollable viewport for rendering a slice of terminal content.
    class Viewport
      attr_accessor :width #: Integer
      attr_accessor :height #: Integer
      attr_accessor :scroll_offset #: Integer
      attr_reader :content #: String

      # @rbs width: Integer
      # @rbs height: Integer
      def initialize(width: 80, height: 24) #: void
        @width = width
        @height = height
        @content = ''
        @scroll_offset = 0
      end

      def view #: String
        lines = @content.split("\n")
        visible = lines[@scroll_offset, @height] || []
        visible << '' while visible.length < @height
        visible.join("\n")
      end

      def goto_bottom #: Integer
        lines = @content.split("\n")
        max_offset = [lines.length - @height, 0].max
        @scroll_offset = max_offset
      end

      def at_bottom? #: bool
        lines = @content.split("\n")
        lines.length <= @height || @scroll_offset >= lines.length - @height
      end

      # @rbs text: String
      def content=(text) #: Integer
        @content = text
        @scroll_offset = 0
      end
    end
  end
end

# frozen_string_literal: true

require 'pastel'
require 'unicode/display_width'
require_relative 'ansi'

module Tinyagent
  module Tui
    # Terminal styling helper for color, width, padding, and bordered boxes.
    class Style
      ROUNDED_BORDER = :rounded

      # @rbs @foreground_color: String?
      # @rbs @border_type: Symbol?
      # @rbs @padding_top: Integer
      # @rbs @padding_right: Integer
      # @rbs @padding_bottom: Integer
      # @rbs @padding_left: Integer
      # @rbs @width_value: Integer?
      # @rbs @pastel: untyped

      def initialize #: void
        @foreground_color = nil
        @border_type = nil
        @padding_top = 0
        @padding_right = 0
        @padding_bottom = 0
        @padding_left = 0
        @width_value = nil
        @pastel = Pastel.new(enabled: true)
      end

      # @rbs color: String
      def foreground(color) #: Style
        @foreground_color = color
        self
      end

      # @rbs type: Symbol
      def border(type) #: Style
        @border_type = type
        self
      end

      # @rbs top: Integer
      # @rbs right: Integer
      # @rbs bottom: Integer?
      # @rbs left: Integer?
      def padding(top, right, bottom = nil, left = nil) #: Style
        @padding_top = top
        @padding_right = right
        @padding_bottom = bottom || top
        @padding_left = left || right
        self
      end

      # @rbs width_value: Integer
      def width(width_value) #: Style
        @width_value = width_value
        self
      end

      # @rbs text: String
      def render(text) #: String
        result = text

        result = apply_foreground(result) if @foreground_color

        if @border_type || @padding_top.positive? || @padding_right.positive?
          result = apply_box(result)
        elsif @width_value
          result = wrap_text(result, @width_value || 0)
        end

        result
      end

      # @rbs text: String
      def self.width(text) #: Integer
        Ansi.display_width(text)
      end

      # @rbs text: String
      def self.height(text) #: Integer
        Ansi.display_height(text)
      end

      private

      # @rbs text: String
      def apply_foreground(text) #: String
        foreground_color = @foreground_color
        if foreground_color&.match?(/\A\d+\z/)
          color_code = foreground_color.to_i
          "\e[38;5;#{color_code}m#{text}\e[0m"
        elsif foreground_color
          @pastel.decorate(text, foreground_color.to_sym)
        else
          text
        end
      end

      # @rbs text: String
      # @rbs width: Integer
      def wrap_text(text, width) #: String
        lines = text.split("\n")
        wrapped = lines.flat_map do |line|
          Ansi.strip(line).length <= width ? line : wrap_line(line, width)
        end
        wrapped.join("\n")
      end

      # @rbs line: String, width: Integer
      # @rbs width: Integer
      def wrap_line(line, width) #: Array[String]
        stripped = Ansi.strip(line)
        result_lines = []
        current = +''
        stripped.chars.each do |char|
          char_width = Unicode::DisplayWidth.of(char)
          if Ansi.display_width(current) + char_width > width
            result_lines << current
            current = +''
          end
          current << char
        end
        result_lines << current unless current.empty?
        result_lines
      end

      # @rbs text: String
      def apply_box(text) #: String
        content_width = @width_value || (Ansi.display_width(text) + @padding_left + @padding_right)

        content_lines = text.split("\n")
        padded_lines = []
        @padding_top.times { padded_lines << '' }
        content_lines.each do |line|
          padded_line = (' ' * @padding_left) + line + (' ' * @padding_right)
          padded_lines << padded_line
        end
        @padding_bottom.times { padded_lines << '' }

        inner_width = content_width

        if @border_type == :rounded
          render_rounded_box(padded_lines, inner_width)
        else
          padded_lines.join("\n")
        end
      end

      # @rbs lines: Array[String], inner_width: Integer
      # @rbs inner_width: Integer
      def render_rounded_box(lines, inner_width) #: String
        top = "╭#{'─' * inner_width}╮"
        bottom = "╰#{'─' * inner_width}╯"

        result_lines = [top]
        lines.each do |line|
          visible_width = Ansi.display_width(line)
          padding_needed = inner_width - visible_width
          result_lines << "│#{line}#{' ' * [padding_needed, 0].max}│"
        end
        result_lines << bottom

        @foreground_color ? apply_foreground(result_lines.join("\n")) : result_lines.join("\n")
      end
    end
  end
end

# frozen_string_literal: true

require 'pastel'
require_relative '../core/key_message'

module Tinyagent
  module Tui
    # Single-line terminal text input with a movable cursor.
    class TextInput
      attr_accessor :width #: Integer
      attr_accessor :placeholder #: String
      attr_accessor :prompt #: String

      # @rbs @focused: bool
      # @rbs @cursor_pos: Integer
      # @rbs @pastel: untyped

      def initialize #: void
        @value = ''
        @focused = true
        @width = 30
        @placeholder = ''
        @prompt = '┃ '
        @cursor_pos = 0
        @pastel = Pastel.new
      end

      attr_reader :value #: String

      # @rbs val: String
      def value=(val) #: String
        @value = val
        @cursor_pos = val.length
      end

      def focus #: bool
        @focused = true
      end

      def blur #: bool
        @focused = false
      end

      def focused? #: bool
        @focused
      end

      def reset #: Integer
        @value = ''
        @cursor_pos = 0
      end

      attr_writer :prompt_style #: Style?

      # @rbs message: KeyMessage
      def update(message) #: Array[untyped]
        case message.key_type
        when KeyMessage::KEY_RUNES
          char = message.to_s
          @value = (@value[0...@cursor_pos] || '') + char + (@value[@cursor_pos..] || '')
          @cursor_pos += char.length
        when KeyMessage::KEY_BACKSPACE
          if @cursor_pos.positive?
            @value = (@value[0...(@cursor_pos - 1)] || '') + (@value[@cursor_pos..] || '')
            @cursor_pos -= 1
          end
        when KeyMessage::KEY_ENTER, KeyMessage::KEY_ESC
          nil
        end
        [self, nil]
      end

      def view #: String
        display_text = if @value.empty? && !@placeholder.empty?
                         @placeholder
                       else
                         @value
                       end

        prompt_style = @prompt_style
        prompt_str = if prompt_style
                       prompt_style.render(@prompt)
                     else
                       @prompt
                     end

        if @focused
          "#{prompt_str}#{display_text}"
        else
          display_text
        end
      end
    end
  end
end

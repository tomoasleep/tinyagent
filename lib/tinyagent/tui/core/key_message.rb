# frozen_string_literal: true

module Tinyagent
  module Tui
    # Keyboard input message used by the custom TUI runtime.
    class KeyMessage < Message
      KEY_ENTER = 'enter'
      KEY_ESC = 'esc'
      KEY_UP = 'up'
      KEY_DOWN = 'down'
      KEY_TAB = 'tab'
      KEY_BACKSPACE = 'backspace'
      KEY_CTRL_C = 'ctrl+c'
      KEY_CTRL_P = 'ctrl+p'
      KEY_NULL = 'null'
      KEY_RUNES = 'runes'

      attr_reader :key_type #: String
      attr_reader :runes #: Array[Integer]
      attr_reader :alt #: bool
      attr_reader :name #: String?

      # @rbs key_type: String
      # @rbs runes: Array[Integer]
      # @rbs alt: bool
      # @rbs name: String?
      def initialize(key_type:, runes: [], alt: false, name: nil) #: void
        @key_type = key_type
        @runes = runes
        @alt = alt
        @name = name
        super()
      end

      # @rbs key_type: String
      # @rbs runes: Array[Integer]
      # @rbs alt: bool
      # @rbs name: String?
      def self.create(key_type:, runes: [], alt: false, name: nil) #: KeyMessage
        new(key_type: key_type, runes: runes, alt: alt, name: name)
      end

      def to_s #: String
        if key_type == KEY_RUNES
          runes.map(&:chr).join
        else
          key_type
        end
      end
    end
  end
end

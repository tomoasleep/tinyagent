# frozen_string_literal: true

require 'bubbletea'

module Tinyagent
  module Tui
    class Chat
      # Renders chat messages into viewport content string.
      # Manages message state via Bubbletea::Model.
      class ChatViewport
        include Bubbletea::Model

        # @rbs @messages: Array[untyped]

        # Message sent to refresh the viewport with new messages.
        class RefreshMessagesMessage < Bubbletea::Message
          attr_reader :messages #: Array[untyped]

          # @rbs messages: Array[untyped]
          def initialize(messages) #: void
            super()
            @messages = messages
          end
        end

        def initialize #: void
          @messages = []
        end

        def init #: Array[untyped]
          [self, nil]
        end

        # @rbs message: Bubbletea::Message
        def update(message) #: Array[untyped]
          @messages = message.messages if message.is_a?(RefreshMessagesMessage)
          [self, nil]
        end

        def view #: String
          return help_text if @messages.empty?

          @messages.map { |msg| format_message(msg) }.join("\n")
        end

        private

        # @rbs msg: untyped
        def format_message(msg) #: String
          case msg.role
          when :user
            "You: #{msg.content}"
          when :assistant
            "Assistant: #{msg.content}"
          when :tool
            tool_name = msg.tool_name || 'tool'
            content = msg.content.to_s
            content = "#{content[0..197]}..." if content.length > 200
            "\u2699 #{tool_name}\n  #{content}"
          else
            msg.content.to_s
          end
        end

        def help_text #: String
          <<~TEXT
            Welcome to tinyagent chat!

            Press i to enter input mode
            Press Ctrl+P to open command palette
            Press q or Ctrl+C to quit
            Use /clear, /compact, /usage for commands
          TEXT
        end
      end
    end
  end
end

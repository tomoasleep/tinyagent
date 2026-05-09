# frozen_string_literal: true

require 'bubbletea'
require 'lipgloss'

module Tinyagent
  module Tui
    class Chat
      # Renders chat messages into viewport content string.
      # Manages message state via Bubbletea::Model.
      class ChatViewport
        include Bubbletea::Model

        # @rbs @messages: Array[untyped]
        # @rbs @width: Integer

        USER_STYLE = Lipgloss::Style.new.foreground('5') #: Lipgloss::Style
        ASSISTANT_STYLE = Lipgloss::Style.new.foreground('6') #: Lipgloss::Style
        TOOL_STYLE = Lipgloss::Style.new.foreground('3') #: Lipgloss::Style

        # Message sent to refresh the viewport with new messages.
        class RefreshMessagesMessage < Bubbletea::Message
          attr_reader :messages #: Array[untyped]

          # @rbs messages: Array[untyped]
          def initialize(messages) #: void
            super()
            @messages = messages
          end
        end

        # @rbs width: Integer
        def initialize(width: 0) #: void
          @messages = []
          @width = width
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

          lines = @messages.map { |msg| format_message(msg) }
          wrapped = @width.positive? ? wrap_lines(lines) : lines
          wrapped.join("\n")
        end

        private

        # @rbs lines: Array[String]
        def wrap_lines(lines) #: Array[String]
          lines.flat_map do |line|
            stripped = Bubbles::ANSI.strip(line)
            if stripped.length <= @width
              line
            else
              Lipgloss::Style.new.width(@width).render(line).split("\n")
            end
          end
        end

        # @rbs msg: untyped
        def format_message(msg) #: String
          case msg.role
          when :user
            "#{USER_STYLE.render('You:')} #{msg.content}"
          when :assistant
            "#{ASSISTANT_STYLE.render('Assistant:')} #{msg.content}"
          when :tool
            tool_name = msg.tool_name || 'tool'
            content = msg.content.to_s
            content = "#{content[0..197]}..." if content.length > 200
            "#{TOOL_STYLE.render("⚙ #{tool_name}")}\n  #{content}"
          else
            msg.content.to_s
          end
        end

        def help_text #: String
          <<~TEXT
            Welcome to tinyagent chat!

            Press Ctrl+P to open command palette
            Press Ctrl+C to quit
            Use /clear, /compact, /usage for commands
          TEXT
        end
      end
    end
  end
end

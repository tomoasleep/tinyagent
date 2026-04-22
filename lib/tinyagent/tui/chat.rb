# frozen_string_literal: true

require 'bubbletea'
require 'bubbles'
require 'lipgloss'

module Tinyagent
  module Tui
    # Interactive chat TUI built on Bubbletea Elm Architecture.
    class Chat
      include Bubbletea::Model

      class CompletionDoneMessage < Bubbletea::Message; end

      # Error message sent when the LLM completion fails.
      class CompletionErrorMessage < Bubbletea::Message
        attr_reader :error

        def initialize(error)
          super()
          @error = error
        end
      end

      attr_reader :state, :thread, :viewport

      def initialize(thread: nil)
        @thread = thread || Tinyagent::Thread.create
        @state = :idle
        @width = 80
        @height = 24
        @status_message = ''
        @viewport = Bubbles::Viewport.new(width: @width, height: @height - 3)
        @text_input = Bubbles::TextInput.new
        @text_input.width = @width - 2
        @text_input.placeholder = 'Type a message...'
        @spinner = Bubbles::Spinner.new
        refresh_viewport
      end

      def init
        [self, Bubbletea.enter_alt_screen]
      end

      def update(message)
        case message
        when Bubbletea::WindowSizeMessage
          handle_resize(message)
        when Bubbletea::KeyMessage
          handle_key(message)
        when Bubbles::Spinner::TickMessage
          handle_spinner_tick(message)
        when CompletionDoneMessage
          handle_completion_done
        when CompletionErrorMessage
          handle_completion_error(message)
        else
          [self, nil]
        end
      end

      def view
        lines = []

        lines << viewport.view

        separator = Lipgloss::Style.new.foreground('240').render('─' * @width)
        lines << separator

        case @state
        when :input
          lines << @text_input.view
        when :thinking
          spinner_view = "#{@spinner.view} Thinking..."
          lines << Lipgloss::Style.new.foreground('205').render(spinner_view)
        else
          help = status_bar
          lines << help
        end

        lines.join("\n")
      end

      def refresh_viewport
        content = build_messages_content
        @viewport.content = content
        @viewport.goto_bottom unless @viewport.at_bottom?
      end

      private

      def handle_resize(message)
        @width = message.width
        @height = message.height
        @viewport.width = @width
        @viewport.height = [@height - 3, 1].max
        @text_input.width = [@width - 2, 1].max
        refresh_viewport
        [self, nil]
      end

      def handle_key(message)
        case message.to_s
        when 'ctrl+c'
          [self, Bubbletea.quit]
        else
          case @state
          when :idle
            handle_idle_key(message)
          when :input
            handle_input_key(message)
          when :thinking
            [self, nil]
          end
        end
      end

      def handle_idle_key(message)
        case message.to_s
        when 'q'
          [self, Bubbletea.quit]
        when 'i'
          enter_input_mode
        else
          @viewport, cmd = @viewport.update(message)
          [self, cmd]
        end
      end

      def handle_input_key(message)
        case message.to_s
        when 'esc'
          exit_input_mode
        else
          @text_input, cmd = @text_input.update(message)
          if message.enter?
            submit_message
          else
            [self, cmd]
          end
        end
      end

      def enter_input_mode
        @state = :input
        @status_message = ''
        @text_input.focus
        [self, nil]
      end

      def exit_input_mode
        @state = :idle
        @text_input.blur
        @text_input.reset
        [self, nil]
      end

      def submit_message
        text = @text_input.value.strip
        return exit_input_mode if text.empty?

        if text.start_with?('/')
          handle_slash_command(text)
        else
          send_user_message(text)
        end
      end

      def handle_slash_command(text)
        case text.downcase
        when '/clear'
          @thread.clear
          @status_message = 'Cleared.'
        when '/compact'
          @status_message = 'Compact not yet available.'
        when '/usage'
          handle_usage_command
        else
          @status_message = "Unknown command: #{text}"
        end
        refresh_viewport
        exit_input_mode
      end

      def handle_usage_command
        usage = @thread.token_usage
        @status_message = if usage
                            "Tokens: #{usage.total_tokens} (prompt: #{usage.prompt_tokens}, completion: #{usage.completion_tokens})"
                          else
                            'No token usage data.'
                          end
      end

      def send_user_message(text)
        @thread.add_message(role: :user, content: text)
        @text_input.reset
        @text_input.blur
        @state = :thinking
        refresh_viewport

        captured_thread = @thread
        cmd = lambda {
          loop = CompletionLoop.new(thread: captured_thread)
          begin
            loop.completion_loop
          rescue StandardError => e
            next CompletionErrorMessage.new(e)
          end
          CompletionDoneMessage.new
        }

        [self, Bubbletea.batch(cmd, @spinner.tick)]
      end

      def handle_spinner_tick(message)
        @spinner, cmd = @spinner.update(message)
        [self, cmd]
      end

      def handle_completion_done
        @state = :idle
        refresh_viewport
        [self, nil]
      end

      def handle_completion_error(message)
        @state = :idle
        @status_message = "Error: #{message.error.message}"
        refresh_viewport
        [self, nil]
      end

      def build_messages_content
        messages = @thread.messages_dataset.all
        return help_text if messages.empty?

        messages.map { |msg| format_message(msg) }.join("\n")
      end

      def format_message(msg)
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

      def help_text
        <<~TEXT
          Welcome to tinyagent chat!

          Press i to enter input mode
          Press q or Ctrl+C to quit
          Use /clear, /compact, /usage for commands
        TEXT
      end

      def status_bar
        parts = []
        parts << @status_message if @status_message && !@status_message.empty?

        usage = @thread.token_usage
        parts << "tokens:#{usage.total_tokens}" if usage

        bar = if parts.empty?
                'Press i to input | q to quit'
              else
                parts.join(' | ')
              end

        Lipgloss::Style.new.foreground('241').render(bar)
      end
    end
  end
end

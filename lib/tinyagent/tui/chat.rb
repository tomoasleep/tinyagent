# frozen_string_literal: true

require 'bubbletea'
require 'bubbles'
require 'lipgloss'

require_relative 'chat/chat_viewport'
require_relative 'chat/palette_component'
require_relative 'chat/status_bar'

module Tinyagent
  module Tui
    # Interactive chat TUI built on Bubbletea Elm Architecture.
    class Chat
      include Bubbletea::Model

      class CompletionDoneMessage < Bubbletea::Message; end

      # Error message sent when the LLM completion fails.
      class CompletionErrorMessage < Bubbletea::Message
        attr_reader :error #: Exception

        # @rbs error: Exception
        def initialize(error) #: void
          super()
          @error = error
        end
      end

      attr_reader :state #: Symbol
      attr_reader :thread #: Tinyagent::Thread
      attr_reader :viewport #: Bubbles::Viewport

      # @rbs @width: Integer
      # @rbs @height: Integer
      # @rbs @status_message: String
      # @rbs @text_input: Bubbles::TextArea
      # @rbs @spinner: Bubbles::Spinner
      # @rbs @chat_viewport: ChatViewport
      # @rbs @palette_component: PaletteComponent
      # @rbs @status_bar_component: StatusBar

      # @rbs thread: Tinyagent::Thread?
      def initialize(thread: nil) #: void
        @thread = thread || Tinyagent::Thread.create
        @state = :idle
        @width = 80
        @height = 24
        @status_message = ''
        @viewport = Bubbles::Viewport.new(width: @width, height: @height - 5)
        @text_input = Bubbles::TextArea.new(width: @width - 2, height: 3)
        @text_input.placeholder = 'Send a message...'
        @text_input.show_line_numbers = false
        @text_input.prompt = '┃ '
        @spinner = Bubbles::Spinner.new
        @chat_viewport = ChatViewport.new(width: @width)
        @palette_component = PaletteComponent.new
        @status_bar_component = StatusBar.new
        refresh_viewport
      end

      def init #: Array[untyped]
        [self, Bubbletea.enter_alt_screen]
      end

      # @rbs message: Bubbletea::Message
      def update(message) #: Array[untyped]
        if palette_active?
          return [self, Bubbletea.quit] if message.is_a?(Bubbletea::KeyMessage) && message.to_s == 'ctrl+c'

          _, cmd = @palette_component.update(message)
          if cmd.is_a?(PaletteComponent::CommandSelectedMessage)
            @state = :idle
            handle_palette_command(cmd.key)
            [self, nil]
          elsif cmd.is_a?(PaletteComponent::ModelSelectedMessage)
            @state = :idle
            config = Tinyagent::Configuration.new
            config.current_provider = cmd.provider
            config.current_model = cmd.model
            @status_message = "Model set to #{cmd.provider}/#{cmd.model}"
            refresh_viewport
            [self, nil]
          elsif @palette_component.closed?
            @state = :idle
            refresh_viewport
            [self, nil]
          elsif @palette_component.provider_select_state?
            @state = :provider_select
            [self, cmd]
          elsif @palette_component.model_select_state?
            @state = :model_select
            [self, cmd]
          else
            @state = :palette
            [self, cmd]
          end
        else
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
      end

      def view #: String
        lines = [] #: Array[String]

        main_content = if palette_active?
                         @palette_component.view(@viewport.view, @width, @height)
                       else
                         @viewport.view
                       end
        lines << main_content

        separator = Lipgloss::Style.new.foreground('240').render('─' * @width)
        lines << separator

        bottom_line = case @state
                      when :input
                        @text_input.view
                      when :palette, :provider_select, :model_select
                        Lipgloss::Style.new.foreground('241').render(@palette_component.help_text)
                      when :thinking
                        spinner_view = "#{@spinner.view} Thinking..."
                        Lipgloss::Style.new.foreground('205').render(spinner_view)
                      else
                        @status_bar_component.view
                      end
        lines << bottom_line

        lines.join("\n")
      end

      def refresh_viewport #: void
        @chat_viewport = ChatViewport.new(width: @width)
        @chat_viewport, _cmd = @chat_viewport.update(ChatViewport::RefreshMessagesMessage.new(@thread.messages_dataset.all))
        config = Tinyagent::Configuration.new
        @status_bar_component, _cmd = @status_bar_component.update(StatusBar::UpdateStatusMessage.new(@status_message))
        @status_bar_component, _cmd = @status_bar_component.update(StatusBar::UpdateModelInfoMessage.new(config.current_provider, config.current_model))
        @status_bar_component, _cmd = @status_bar_component.update(StatusBar::UpdateTokenUsageMessage.new(@thread.token_usage))
        @viewport.content = @chat_viewport.view
        @viewport.goto_bottom unless @viewport.at_bottom?
      end

      private

      # @rbs message: Bubbletea::WindowSizeMessage
      def handle_resize(message) #: Array[untyped]
        @width = message.width
        @height = message.height
        @viewport.width = @width
        @viewport.height = [@height - @text_input.height - 2, 1].max
        @text_input.width = [@width - 2, 1].max
        refresh_viewport
        [self, nil]
      end

      # @rbs message: Bubbletea::KeyMessage
      def handle_key(message) #: Array[untyped]
        result = case message.to_s
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
        result || [self, nil]
      end

      # @rbs message: Bubbletea::KeyMessage
      def handle_idle_key(message) #: Array[untyped]
        case message.to_s
        when 'q'
          [self, Bubbletea.quit]
        when 'i'
          enter_input_mode
        when 'ctrl+p'
          open_palette
        else
          @viewport, cmd = @viewport.update(message)
          [self, cmd]
        end
      end

      # @rbs message: Bubbletea::KeyMessage
      def handle_input_key(message) #: Array[untyped]
        case message.to_s
        when 'esc'
          exit_input_mode
        when 'ctrl+p'
          @text_input.blur
          @text_input.reset
          open_palette
        when 'enter'
          submit_message
        else
          @text_input, cmd = @text_input.update(message)
          [self, cmd]
        end
      end

      def open_palette #: Array[untyped]
        @state = :palette
        @palette_component.open
        [self, nil]
      end

      def palette_active? #: bool
        %i[palette provider_select model_select].include?(@state)
      end

      # @rbs key: Symbol
      def handle_palette_command(key) #: void
        case key
        when :clear
          @thread.clear
          @status_message = 'Cleared.'
        when :compact
          @status_message = 'Compact not yet available.'
        when :usage
          handle_usage_command
        end
        refresh_viewport
      end

      def enter_input_mode #: Array[untyped]
        @state = :input
        @status_message = ''
        @text_input.focus
        [self, nil]
      end

      def exit_input_mode #: Array[untyped]
        @state = :idle
        @text_input.blur
        @text_input.reset
        [self, nil]
      end

      def submit_message #: untyped
        text = @text_input.value.strip
        return exit_input_mode if text.empty?

        if text.start_with?('/')
          handle_slash_command(text)
        else
          send_user_message(text)
        end
      end

      # @rbs text: String
      def handle_slash_command(text) #: void
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

      def handle_usage_command #: void
        usage = @thread.token_usage
        @status_message = if usage
                            "Tokens: #{usage.total_tokens} (prompt: #{usage.prompt_tokens}, completion: #{usage.completion_tokens})"
                          else
                            'No token usage data.'
                          end
      end

      # @rbs text: String
      def send_user_message(text) #: Array[untyped]
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

      # @rbs message: Bubbles::Spinner::TickMessage
      def handle_spinner_tick(message) #: Array[untyped]
        @spinner, cmd = @spinner.update(message)
        [self, cmd]
      end

      def handle_completion_done #: Array[untyped]
        @state = :idle
        refresh_viewport
        [self, nil]
      end

      # @rbs message: CompletionErrorMessage
      def handle_completion_error(message) #: Array[untyped]
        @state = :idle
        @status_message = "Error: #{message.error.message}"
        refresh_viewport
        [self, nil]
      end
    end
  end
end

# frozen_string_literal: true

require 'tinyagent/tui/core'
require 'tinyagent/tui/components'

require_relative 'chat/chat_viewport'
require_relative 'chat/palette_component'
require_relative 'chat/status_bar'

module Tinyagent
  module Tui
    # Interactive chat TUI built on custom Elm Architecture.
    class Chat
      include Tinyagent::Tui::Model

      class CompletionDoneMessage < Tinyagent::Tui::Message; end

      # Error message sent when the LLM completion fails.
      class CompletionErrorMessage < Tinyagent::Tui::Message
        attr_reader :error #: Exception

        # @rbs error: Exception
        def initialize(error) #: void
          super()
          @error = error
        end
      end

      attr_reader :state #: Symbol
      attr_reader :thread #: Tinyagent::Thread
      attr_reader :viewport #: Tinyagent::Tui::Viewport

      # @rbs @width: Integer
      # @rbs @height: Integer
      # @rbs @status_message: String
      # @rbs @text_input: Tinyagent::Tui::TextInput
      # @rbs @spinner: Tinyagent::Tui::Spinner
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
        @viewport = Tinyagent::Tui::Viewport.new(width: @width, height: @height - 5)
        @text_input = Tinyagent::Tui::TextInput.new
        @text_input.placeholder = 'Send a message...'
        @text_input.prompt = '┃ '
        @text_input.prompt_style = Tinyagent::Tui::Style.new.foreground('209')
        @text_input.width = @width - 2
        @text_input.focus
        @spinner = Tinyagent::Tui::Spinner.new
        @chat_viewport = ChatViewport.new(width: @width)
        @palette_component = PaletteComponent.new
        @status_bar_component = StatusBar.new
        refresh_viewport
      end

      def init #: Array[untyped]
        [self, Tinyagent::Tui::Commands.enter_alt_screen]
      end

      # @rbs message: Tinyagent::Tui::Message
      def update(message) #: Array[untyped]
        if palette_active?
          return [self, Tinyagent::Tui::Commands.quit] if message.is_a?(Tinyagent::Tui::KeyMessage) && message.to_s == 'ctrl+c'

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
          when Tinyagent::Tui::WindowSizeMessage
            handle_resize(message)
          when Tinyagent::Tui::KeyMessage
            handle_key(message)
          when Tinyagent::Tui::Spinner::TickMessage
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
        lines = []

        main_content = if palette_active?
                         @palette_component.view(@viewport.view, @width, @height)
                       else
                         @viewport.view
                       end
        lines << main_content

        separator = Tinyagent::Tui::Style.new.foreground('240').render('─' * @width)
        lines << separator

        case @state
        when :palette, :provider_select, :model_select
          lines << Tinyagent::Tui::Style.new.foreground('241').render(@palette_component.help_text)
        when :thinking
          spinner_view = "#{@spinner.view} Thinking..."
          lines << Tinyagent::Tui::Style.new.foreground('205').render(spinner_view)
          lines << @status_bar_component.footer_view
        else
          status_line = @status_bar_component.status_view
          lines << status_line if status_visible?
          lines << @text_input.view
          lines << @status_bar_component.footer_view
        end

        lines.join("\n")
      end

      def refresh_viewport #: void
        @chat_viewport = ChatViewport.new(width: @width)
        @chat_viewport, _cmd = @chat_viewport.update(ChatViewport::RefreshMessagesMessage.new(@thread.messages_dataset.all))
        config = Tinyagent::Configuration.new
        @status_bar_component, _cmd = @status_bar_component.update(StatusBar::UpdateStatusMessage.new(@status_message))
        @status_bar_component, _cmd = @status_bar_component.update(StatusBar::UpdateModelInfoMessage.new(config.current_provider, config.current_model))
        @status_bar_component, _cmd = @status_bar_component.update(StatusBar::UpdateTokenUsageMessage.new(@thread.token_usage))
        @viewport.height = [@height - bottom_reserved_height, 1].max
        update_text_input_prompt
        @viewport.content = @chat_viewport.view
        @viewport.goto_bottom unless @viewport.at_bottom?
        nil
      end

      private

      # @rbs message: Tinyagent::Tui::WindowSizeMessage
      def handle_resize(message) #: Array[untyped]
        @width = message.width
        @height = message.height
        @viewport.width = @width
        @viewport.height = [@height - bottom_reserved_height, 1].max
        @text_input.width = [@width - 2, 1].max
        refresh_viewport
        [self, nil]
      end

      # @rbs message: Tinyagent::Tui::KeyMessage
      def handle_key(message) #: Array[untyped]
        result = case message.to_s
                 when 'ctrl+c'
                   [self, Tinyagent::Tui::Commands.quit]
                 else
                   case @state
                   when :idle
                     handle_idle_key(message)
                   when :thinking
                     [self, nil]
                   end
                 end
        result || [self, nil]
      end

      # @rbs message: Tinyagent::Tui::KeyMessage
      def handle_idle_key(message) #: Array[untyped]
        case message.to_s
        when 'esc'
          @text_input.reset
          [self, nil]
        when 'ctrl+p'
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
        nil
      end

      def submit_message #: Array[untyped]
        text = @text_input.value.strip
        return [self, nil] if text.empty?

        if text.start_with?('/')
          handle_slash_command(text)
          [self, nil]
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
        @text_input.reset
        refresh_viewport
        nil
      end

      def handle_usage_command #: String
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

        [self, Tinyagent::Tui::Commands.batch([cmd])]
      end

      # @rbs message: Tinyagent::Tui::Spinner::TickMessage
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

      def update_text_input_prompt #: String
        @text_input.prompt = '┃ '
      end

      def bottom_reserved_height #: Integer
        case @state
        when :palette, :provider_select, :model_select
          2
        when :thinking
          3
        else
          @text_input.view.split("\n").length + (status_visible? ? 3 : 2)
        end
      end

      def status_visible? #: bool
        !Tinyagent::Tui::Ansi.strip(@status_bar_component.status_view).empty?
      end
    end
  end
end

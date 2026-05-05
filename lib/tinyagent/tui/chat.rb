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

      COMMANDS = [
        { title: 'clear', key: :clear },
        { title: 'compact', key: :compact },
        { title: 'usage', key: :usage }
      ].freeze

      PALETTE_WIDTH = 36

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
        @command_palette = Bubbles::List.new(COMMANDS.dup, width: PALETTE_WIDTH - 6, height: COMMANDS.length)
        @command_palette.show_title = false
        @command_palette.show_filter = false
        @command_palette.show_pagination = false
        @command_palette.show_status_bar = false
        @command_palette.fill_height = false
        @palette_filter_input = Bubbles::TextInput.new
        @palette_filter_input.prompt = ''
        @palette_filter_input.placeholder = 'Type to filter...'
        @palette_filter_input.width = PALETTE_WIDTH - 6
        @provider_filter_input = Bubbles::TextInput.new
        @provider_filter_input.prompt = ''
        @provider_filter_input.placeholder = 'Type to filter...'
        @provider_filter_input.width = PALETTE_WIDTH - 6
        @model_filter_input = Bubbles::TextInput.new
        @model_filter_input.prompt = ''
        @model_filter_input.placeholder = 'Type to filter...'
        @model_filter_input.width = PALETTE_WIDTH - 6
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

        lines << case @state
                 when :palette
                   palette_overlay_view
                 when :provider_select, :model_select
                   model_select_overlay_view
                 else
                   viewport.view
                 end

        separator = Lipgloss::Style.new.foreground('240').render('─' * @width)
        lines << separator

        case @state
        when :input
          lines << @text_input.view
        when :palette
          lines << Lipgloss::Style.new.foreground('241').render('↑↓ navigate | enter: execute | esc: close')
        when :provider_select
          lines << Lipgloss::Style.new.foreground('241').render('↑↓ navigate | enter: choose provider | esc: close')
        when :model_select
          lines << Lipgloss::Style.new.foreground('241').render('↑↓ navigate | enter: choose model | esc: close')
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
        @command_palette.width = PALETTE_WIDTH - 6
        @palette_filter_input.width = PALETTE_WIDTH - 6
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
          when :palette
            handle_palette_key(message)
          when :provider_select
            handle_provider_select_key(message)
          when :model_select
            handle_model_select_key(message)
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
        when 'ctrl+p'
          open_palette
        when 'ctrl+m'
          open_provider_select
        else
          @viewport, cmd = @viewport.update(message)
          [self, cmd]
        end
      end

      def handle_input_key(message)
        case message.to_s
        when 'esc'
          exit_input_mode
        when 'ctrl+p'
          @text_input.blur
          @text_input.reset
          open_palette
        else
          @text_input, cmd = @text_input.update(message)
          if message.enter?
            submit_message
          else
            [self, cmd]
          end
        end
      end

      def handle_palette_key(message)
        case message.to_s
        when 'esc', 'ctrl+p'
          close_palette
        when 'enter'
          execute_palette_command
        when 'up', 'k'
          @command_palette.select_prev
          [self, nil]
        when 'down', 'j'
          @command_palette.select_next
          [self, nil]
        else
          @palette_filter_input, cmd = @palette_filter_input.update(message)
          filter_commands
          [self, cmd]
        end
      end

      def handle_provider_select_key(message)
        case message.to_s
        when 'esc'
          close_provider_select
        when 'enter'
          execute_provider_select
        when 'up', 'k'
          @provider_palette.select_prev
          [self, nil]
        when 'down', 'j'
          @provider_palette.select_next
          [self, nil]
        else
          @provider_filter_input, cmd = @provider_filter_input.update(message)
          filter_providers
          [self, cmd]
        end
      end

      def handle_model_select_key(message)
        case message.to_s
        when 'esc'
          close_model_select
        when 'enter'
          execute_model_select
        when 'up', 'k'
          @model_palette.select_prev
          [self, nil]
        when 'down', 'j'
          @model_palette.select_next
          [self, nil]
        else
          @model_filter_input, cmd = @model_filter_input.update(message)
          filter_models
          [self, cmd]
        end
      end

      def filter_commands
        query = @palette_filter_input.value.strip
        if query.empty?
          @command_palette.items = COMMANDS.dup
        else
          filtered = COMMANDS.select { |cmd| fuzzy_match?(query, cmd[:title]) }
          @command_palette.items = filtered
        end
      end

      def filter_providers
        query = @provider_filter_input.value.strip
        providers = all_provider_items
        if query.empty?
          @provider_palette.items = providers
        else
          filtered = providers.select { |p| fuzzy_match?(query, p[:title]) }
          @provider_palette.items = filtered
        end
      end

      def filter_models
        query = @model_filter_input.value.strip
        models = all_model_items
        if query.empty?
          @model_palette.items = models
        else
          filtered = models.select { |m| fuzzy_match?(query, m[:title]) }
          @model_palette.items = filtered
        end
      end

      def all_provider_items
        catalog = ModelsDev::Catalog.new
        catalog.openai_compatible_providers.map do |id, data|
          { title: data['name'] || id, key: id }
        end
      end

      def fuzzy_match?(query, target)
        return true if query.empty?

        query = query.downcase
        target = target.downcase
        idx = -1
        query.each_char.all? { |c| idx = target.index(c, idx + 1) }
      end

      def palette_overlay_view
        generic_overlay_view(@command_palette, @palette_filter_input)
      end

      def model_select_overlay_view
        list = @state == :provider_select ? @provider_palette : @model_palette
        filter = @state == :provider_select ? @provider_filter_input : @model_filter_input
        generic_overlay_view(list, filter)
      end

      def generic_overlay_view(list, filter_input)
        inner_lines = []
        inner_lines << filter_input.view
        inner_lines << list.view
        inner_lines << Lipgloss::Style.new.foreground('241').render('esc to close')
        inner = inner_lines.join("\n")

        box_style = Lipgloss::Style.new
                                   .border(Lipgloss::ROUNDED_BORDER)
                                   .padding(0, 2)
                                   .width(PALETTE_WIDTH)

        palette_box = box_style.render(inner)
        palette_w = Lipgloss.width(palette_box)
        palette_h = Lipgloss.height(palette_box)

        viewport_content = @viewport.view
        vp_lines = viewport_content.split("\n")

        viewport_height = [@height - 3, 1].max
        vp_lines << '' while vp_lines.length < viewport_height

        overlay_x = [(@width - palette_w) / 2, 0].max

        last_content_line = vp_lines.rindex { |l| Bubbles::ANSI.strip(l).strip != '' }
        overlay_y = last_content_line ? [last_content_line - palette_h + 2, 0].max : 0

        dim_style = Lipgloss::Style.new.foreground('244')

        palette_lines = palette_box.split("\n")
        palette_lines.each_with_index do |pl, i|
          target_y = overlay_y + i
          break if target_y >= vp_lines.length

          plain = Bubbles::ANSI.strip(vp_lines[target_y]).ljust(@width)
          dim_left = dim_style.render(plain[0, overlay_x])
          dim_right = dim_style.render(plain[overlay_x + palette_w, @width - overlay_x - palette_w])
          vp_lines[target_y] = dim_left + pl + dim_right
        end

        vp_lines.join("\n")
      end

      def open_palette
        @state = :palette
        @palette_filter_input.focus
        @palette_filter_input.reset
        @command_palette.items = COMMANDS.dup
        @command_palette.select(0)
        [self, nil]
      end

      def close_palette
        @state = :idle
        @palette_filter_input.blur
        [self, nil]
      end

      def execute_palette_command
        item = @command_palette.selected_item
        case item[:key]
        when :clear
          @thread.clear
          @status_message = 'Cleared.'
        when :compact
          @status_message = 'Compact not yet available.'
        when :usage
          handle_usage_command
        end
        refresh_viewport
        close_palette
      end

      def open_provider_select
        @state = :provider_select
        @provider_filter_input.focus
        @provider_filter_input.reset
        providers = all_provider_items
        @provider_palette = Bubbles::List.new(providers, width: PALETTE_WIDTH - 6, height: [providers.length, 10].min)
        @provider_palette.show_title = false
        @provider_palette.show_filter = false
        @provider_palette.show_pagination = false
        @provider_palette.show_status_bar = false
        @provider_palette.fill_height = false
        @provider_palette.select(0)
        [self, nil]
      end

      def close_provider_select
        @state = :idle
        @provider_filter_input.blur
        [self, nil]
      end

      def execute_provider_select
        item = @provider_palette.selected_item
        @selected_provider = item[:key]
        open_model_select
      end

      def open_model_select
        @state = :model_select
        @model_filter_input.focus
        @model_filter_input.reset
        models = all_model_items(@selected_provider)
        @model_palette = Bubbles::List.new(models, width: PALETTE_WIDTH - 6, height: [models.length, 10].min)
        @model_palette.show_title = false
        @model_palette.show_filter = false
        @model_palette.show_pagination = false
        @model_palette.show_status_bar = false
        @model_palette.fill_height = false
        @model_palette.select(0)
        [self, nil]
      end

      def close_model_select
        @state = :idle
        @model_filter_input.blur
        [self, nil]
      end

      def execute_model_select
        item = @model_palette.selected_item
        config = Tinyagent::Configuration.new
        config.current_provider = @selected_provider
        config.current_model = item[:key]
        @status_message = "Model set to #{@selected_provider}/#{item[:key]}"
        refresh_viewport
        close_model_select
      end

      def all_model_items(provider_id)
        catalog = ModelsDev::Catalog.new
        catalog.models_for(provider_id).map do |id, data|
          { title: data['name'] || id, key: id }
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
          Press Ctrl+P to open command palette
          Press Ctrl+M to change model
          Press q or Ctrl+C to quit
          Use /clear, /compact, /usage for commands
        TEXT
      end

      def status_bar
        parts = []
        parts << @status_message if @status_message && !@status_message.empty?

        usage = @thread.token_usage
        parts << "tokens:#{usage.total_tokens}" if usage

        config = Tinyagent::Configuration.new
        parts << "model:#{config.current_provider}/#{config.current_model}"

        bar = parts.join(' | ')
        Lipgloss::Style.new.foreground('241').render(bar)
      end
    end
  end
end

# frozen_string_literal: true

require 'tinyagent/tui/core'
require 'tinyagent/tui/components'
require_relative 'palette_view'

module Tinyagent
  module Tui
    class Chat
      # Manages palette state transitions and rendering.
      # Includes command palette, provider selection, and model selection.
      class PaletteComponent
        include Tinyagent::Tui::Model

        # @rbs @state: Symbol
        # @rbs @command_palette: Tinyagent::Tui::List
        # @rbs @palette_filter_input: Tinyagent::Tui::TextInput
        # @rbs @provider_filter_input: Tinyagent::Tui::TextInput
        # @rbs @model_filter_input: Tinyagent::Tui::TextInput
        # @rbs @provider_palette: Tinyagent::Tui::List
        # @rbs @model_palette: Tinyagent::Tui::List
        # @rbs @palette_view: PaletteView

        # Message sent when palette is closed without action.
        class PaletteClosedMessage < Tinyagent::Tui::Message; end

        # Message sent when a command is selected.
        class CommandSelectedMessage < Tinyagent::Tui::Message
          attr_reader :key #: Symbol

          # @rbs key: Symbol
          def initialize(key) #: void
            super()
            @key = key
          end
        end

        # Message sent when a model is selected.
        class ModelSelectedMessage < Tinyagent::Tui::Message
          attr_reader :provider #: String
          attr_reader :model #: String

          # @rbs provider: String
          # @rbs model: String
          def initialize(provider, model) #: void
            super()
            @provider = provider
            @model = model
          end
        end

        COMMANDS = [
          { title: 'clear', key: :clear },
          { title: 'compact', key: :compact },
          { title: 'usage', key: :usage },
          { title: 'change model', key: :change_model }
        ].freeze

        PALETTE_WIDTH = 36

        attr_reader :selected_provider #: String?
        attr_reader :selected_model #: String?
        attr_reader :selected_command_key #: Symbol?

        def initialize #: void
          @state = :closed
          @command_palette = Tinyagent::Tui::List.new([], width: 0, height: 0)
          @palette_filter_input = Tinyagent::Tui::TextInput.new
          @palette_filter_input.prompt = ''
          @palette_filter_input.placeholder = 'Type to filter...'
          @palette_filter_input.width = PALETTE_WIDTH - 6
          @provider_filter_input = Tinyagent::Tui::TextInput.new
          @provider_filter_input.prompt = ''
          @provider_filter_input.placeholder = 'Type to filter...'
          @provider_filter_input.width = PALETTE_WIDTH - 6
          @model_filter_input = Tinyagent::Tui::TextInput.new
          @model_filter_input.prompt = ''
          @model_filter_input.placeholder = 'Type to filter...'
          @model_filter_input.width = PALETTE_WIDTH - 6
          @provider_palette = Tinyagent::Tui::List.new([], width: 0, height: 0)
          @model_palette = Tinyagent::Tui::List.new([], width: 0, height: 0)
          @selected_provider = nil
          @selected_model = nil
          @selected_command_key = nil
          @palette_view = PaletteView.new
        end

        def init #: Array[untyped]
          [self, nil]
        end

        # @rbs message: Tinyagent::Tui::Message
        def update(message) #: Array[untyped]
          case message
          when Tinyagent::Tui::KeyMessage
            handle_key(message)
          else
            [self, nil]
          end
        end

        def open #: Symbol?
          @state = :command
          @palette_filter_input.focus
          @palette_filter_input.reset
          @command_palette = Tinyagent::Tui::List.new(COMMANDS.dup, width: PALETTE_WIDTH - 6, height: COMMANDS.length)
          @command_palette.show_title = false
          @command_palette.show_filter = false
          @command_palette.show_pagination = false
          @command_palette.show_status_bar = false
          @command_palette.fill_height = false
          @command_palette.select(0)
          @selected_command_key = nil
          @selected_provider = nil
          @selected_model = nil
        end

        # @rbs viewport_content: String
        # @rbs width: Integer
        # @rbs height: Integer
        def view(viewport_content, width, height) #: String
          case @state
          when :command
            @palette_view.palette_overlay_view(viewport_content, width, height, @command_palette, @palette_filter_input)
          when :provider_select
            @palette_view.model_select_overlay_view(viewport_content, width, height, @provider_palette, @provider_filter_input)
          when :model_select
            @palette_view.model_select_overlay_view(viewport_content, width, height, @model_palette, @model_filter_input)
          else
            viewport_content
          end
        end

        def help_text #: String
          case @state
          when :command
            '↑↓ navigate | enter: execute | esc: close'
          when :provider_select
            '↑↓ navigate | enter: choose provider | esc: close'
          when :model_select
            '↑↓ navigate | enter: choose model | esc: close'
          else
            ''
          end
        end

        def closed? #: bool
          @state == :closed
        end

        def command_state? #: bool
          @state == :command
        end

        def provider_select_state? #: bool
          @state == :provider_select
        end

        def model_select_state? #: bool
          @state == :model_select
        end

        def filter_input_focused? #: bool
          case @state
          when :command
            @palette_filter_input.focused?
          when :provider_select
            @provider_filter_input.focused?
          when :model_select
            @model_filter_input.focused?
          else
            false
          end
        end

        def selected_index #: Integer
          case @state
          when :command
            @command_palette.selected_index
          when :provider_select
            @provider_palette.selected_index
          when :model_select
            @model_palette.selected_index
          else
            0
          end
        end

        def filtered_items #: Array[untyped]
          case @state
          when :command
            @command_palette.items
          when :provider_select
            @provider_palette.items
          when :model_select
            @model_palette.items
          else
            []
          end
        end

        private

        # @rbs message: Tinyagent::Tui::KeyMessage
        def handle_key(message) #: Array[untyped]
          case @state
          when :command
            handle_command_key(message)
          when :provider_select
            handle_provider_select_key(message)
          when :model_select
            handle_model_select_key(message)
          else
            [self, nil]
          end
        end

        # @rbs message: Tinyagent::Tui::KeyMessage
        def handle_command_key(message) #: Array[untyped]
          case message.to_s
          when 'esc', 'ctrl+p'
            close
            [self, PaletteClosedMessage.new]
          when 'enter'
            execute_command
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

        # @rbs message: Tinyagent::Tui::KeyMessage
        def handle_provider_select_key(message) #: Array[untyped]
          case message.to_s
          when 'esc'
            close
            [self, PaletteClosedMessage.new]
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

        # @rbs message: Tinyagent::Tui::KeyMessage
        def handle_model_select_key(message) #: Array[untyped]
          case message.to_s
          when 'esc'
            close
            [self, PaletteClosedMessage.new]
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

        def execute_command #: Array[untyped]
          item = @command_palette.selected_item
          @selected_command_key = item[:key]
          case item[:key]
          when :change_model
            open_provider_select
            [self, nil]
          else
            close
            [self, CommandSelectedMessage.new(item[:key])]
          end
        end

        def execute_provider_select #: Array[untyped]
          item = @provider_palette.selected_item
          @selected_provider = item[:key]
          open_model_select
          [self, nil]
        end

        def execute_model_select #: Array[untyped]
          item = @model_palette.selected_item
          @selected_model = item[:key]
          provider = @selected_provider || ''
          close
          [self, ModelSelectedMessage.new(provider, item[:key])]
        end

        def open_provider_select #: Integer
          @state = :provider_select
          @provider_filter_input.focus
          @provider_filter_input.reset
          providers = all_provider_items
          @provider_palette = Tinyagent::Tui::List.new(providers, width: PALETTE_WIDTH - 6, height: [providers.length, 10].min)
          @provider_palette.show_title = false
          @provider_palette.show_filter = false
          @provider_palette.show_pagination = false
          @provider_palette.show_status_bar = false
          @provider_palette.fill_height = false
          @provider_palette.select(0)
        end

        def open_model_select #: Integer
          @state = :model_select
          @model_filter_input.focus
          @model_filter_input.reset
          models = all_model_items(@selected_provider || '')
          @model_palette = Tinyagent::Tui::List.new(models, width: PALETTE_WIDTH - 6, height: [models.length, 10].min)
          @model_palette.show_title = false
          @model_palette.show_filter = false
          @model_palette.show_pagination = false
          @model_palette.show_status_bar = false
          @model_palette.fill_height = false
          @model_palette.select(0)
        end

        def close #: bool
          @state = :closed
          @palette_filter_input.blur
          @provider_filter_input.blur
          @model_filter_input.blur
        end

        def filter_commands #: Array[untyped]
          query = @palette_filter_input.value.strip
          if query.empty?
            @command_palette.items = COMMANDS.dup
          else
            filtered = COMMANDS.select { |cmd| fuzzy_match?(query, cmd[:title]) }
            @command_palette.items = filtered
          end
        end

        def filter_providers #: Array[untyped]
          query = @provider_filter_input.value.strip
          providers = all_provider_items
          if query.empty?
            @provider_palette.items = providers
          else
            filtered = providers.select { |p| fuzzy_match?(query, p[:title]) }
            @provider_palette.items = filtered
          end
        end

        def filter_models #: Array[untyped]
          query = @model_filter_input.value.strip
          models = all_model_items(@selected_provider || '')
          if query.empty?
            @model_palette.items = models
          else
            filtered = models.select { |m| fuzzy_match?(query, m[:title]) }
            @model_palette.items = filtered
          end
        end

        def all_provider_items #: Array[Hash[Symbol, String]]
          catalog = ModelsDev::Catalog.new
          catalog.openai_compatible_providers.map do |id, data|
            { title: data['name'] || id, key: id }
          end
        end

        # @rbs provider_id: String
        def all_model_items(provider_id) #: Array[Hash[Symbol, String]]
          catalog = ModelsDev::Catalog.new
          catalog.models_for(provider_id).map do |id, data|
            { title: data['name'] || id, key: id }
          end
        end

        # @rbs query: String
        # @rbs target: String
        def fuzzy_match?(query, target) #: bool
          return true if query.empty?

          query = query.downcase
          target = target.downcase
          idx = -1
          query.each_char.all? { |c| idx = target.index(c, idx + 1) }
        end
      end
    end
  end
end

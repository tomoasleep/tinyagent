# frozen_string_literal: true

module Tinyagent
  module ToolDefinitions
    # Tool for displaying help about available bot actions.
    class BotHelp < Base
      class << self
        def actions #: Array[untyped]
          @actions || []
        end

        attr_writer :actions #: Array[untyped]
      end

      self.tool_name = 'bot_help'
      self.tool_title = 'Show help information about this bot (you)'

      self.tool_description = <<~TEXT
        Get help information about available patterns of this bot (you).

        # Hint

        - You can find available commands by using this tool.
        - If user asks for what you can do or usage (e.g. "Tell me the usage", "How do I use it?"), use this tool to respond.
        - If user asks for specific commands, use the 'filter' argument to search for them.
        - If user typed a command that you don't know, use this tool to find out the correct command.
      TEXT

      self.tool_input_schema = {
        type: 'object',
        properties: {
          filter: {
            type: 'string',
            description: 'Optional filter to search for specific commands (e.g., "mcp", "ai", "ping")'
          }
        },
        required: []
      }

      # @rbs arguments: Hash[String, untyped]
      def call(arguments) #: String?
        filter = arguments['filter']

        descriptions = filtered_descriptions(filter)

        if descriptions.empty?
          if filter
            "No description matched to '#{filter}'"
          else
            'No commands available'
          end
        else
          descriptions.join("\n")
        end
      end

      private

      # @rbs filter: String?
      def filtered_descriptions(filter) #: Array[String]
        descriptions = all_descriptions

        if filter
          descriptions.select! do |description|
            description.include?(filter)
          end
        end

        descriptions
      end

      def all_descriptions #: Array[String]
        actions = self.class.actions

        sorted_actions = begin
          actions.sort_by { |a| a[:description].to_s }
        rescue ArgumentError
          actions
        end

        sorted_actions.map do |action|
          "#{action[:pattern]} - #{action[:description]}"
        end
      end
    end
  end
end

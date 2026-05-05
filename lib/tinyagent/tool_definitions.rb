# frozen_string_literal: true

module Tinyagent
  # Tool Definitions for AI Agent
  module ToolDefinitions
    autoload :Base, 'tinyagent/tool_definitions/base'
    autoload :Fetch, 'tinyagent/tool_definitions/fetch'
    autoload :Think, 'tinyagent/tool_definitions/think'
    autoload :BotHelp, 'tinyagent/tool_definitions/bot_help'

    # @rbs request: untyped
    def self.builtins(request:) #: Array[Base]
      [
        Think,
        BotHelp,
        Fetch
      ].select(&:available?).map { |tool_def| tool_def.new(request:) }
    end
  end
end

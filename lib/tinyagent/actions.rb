# frozen_string_literal: true

module Tinyagent
  # Tinyagent actions.
  module Actions
    autoload :AddAiCommand, 'tinyagent/actions/add_ai_command'
    autoload :AddAiMemory, 'tinyagent/actions/add_ai_memory'
    autoload :AddMcp, 'tinyagent/actions/add_mcp'
    autoload :Base, 'tinyagent/actions/base'
    autoload :Chat, 'tinyagent/actions/chat'
    autoload :ListAiCommands, 'tinyagent/actions/list_ai_commands'
    autoload :ListAiMemories, 'tinyagent/actions/list_ai_memories'
    autoload :ListMcp, 'tinyagent/actions/list_mcp'
    autoload :RemoveAiCommand, 'tinyagent/actions/remove_ai_command'
    autoload :RemoveAiMemory, 'tinyagent/actions/remove_ai_memory'
    autoload :RemoveMcp, 'tinyagent/actions/remove_mcp'
    autoload :SetSystemPrompt, 'tinyagent/actions/set_system_prompt'
    autoload :ShowSystemPrompt, 'tinyagent/actions/show_system_prompt'
  end
end

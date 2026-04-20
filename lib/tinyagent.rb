# frozen_string_literal: true

require 'json'

require 'tinyagent/version'

module Tinyagent
  class Error < StandardError; end

  autoload :Actions, 'tinyagent/actions'
  autoload :Agent, 'tinyagent/agent'
  autoload :ChatMessage, 'tinyagent/chat_message'
  autoload :ChatThread, 'tinyagent/chat_thread'
  autoload :ChatThreadAssociations, 'tinyagent/chat_thread_associations'
  autoload :ChatThreadMessages, 'tinyagent/chat_thread_messages'
  autoload :Commands, 'tinyagent/commands'
  autoload :Database, 'tinyagent/database'
  autoload :GlobalSettings, 'tinyagent/global_settings'
  autoload :HttpMcpClient, 'tinyagent/http_mcp_client'
  autoload :LLM, 'tinyagent/llm'
  autoload :CachedValue, 'tinyagent/cached_value'
  autoload :McpClients, 'tinyagent/mcp_clients'
  autoload :McpConfiguration, 'tinyagent/mcp_configuration'
  autoload :PromptCommandDefinition, 'tinyagent/prompt_command_definition'
  autoload :Recordable, 'tinyagent/recordable'
  autoload :RecordSet, 'tinyagent/record_set'
  autoload :Request, 'tinyagent/request'
  autoload :Settings, 'tinyagent/settings'
  autoload :TokenUsage, 'tinyagent/token_usage'
  autoload :Tool, 'tinyagent/tool'
  autoload :ToolDefinitions, 'tinyagent/tool_definitions'
  autoload :User, 'tinyagent/user'
  autoload :UserAiMemories, 'tinyagent/user_ai_memories'
  autoload :UserAssociations, 'tinyagent/user_associations'
  autoload :UserMcpCaches, 'tinyagent/user_mcp_caches'
  autoload :UserMcpClient, 'tinyagent/user_mcp_client'
  autoload :UserMcpConfigurations, 'tinyagent/user_mcp_configurations'
  autoload :UserMcpToolsCaches, 'tinyagent/user_mcp_tools_caches'
  autoload :UserPromptCommandDefinitions, 'tinyagent/user_prompt_command_definitions'

  extend Settings::Accessor

  [
    CachedValue,
    ChatMessage,
    McpConfiguration,
    PromptCommandDefinition,
    TokenUsage
  ]
end

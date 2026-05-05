# frozen_string_literal: true

require 'json'
require 'sequel'

require 'tinyagent/version'

# A tiny AI agent framework with LLM integration and MCP support.
module Tinyagent
  class Error < StandardError; end

  autoload :Agent, 'tinyagent/agent'
  autoload :Cli, 'tinyagent/cli'
  autoload :CompletionLoop, 'tinyagent/completion_loop'
  autoload :Configuration, 'tinyagent/configuration'
  autoload :HttpMcpClient, 'tinyagent/http_mcp_client'
  autoload :LLM, 'tinyagent/llm'
  autoload :McpClients, 'tinyagent/mcp_clients'
  autoload :Message, 'tinyagent/message'
  autoload :Migrations, 'tinyagent/migrations'
  autoload :ModelsDev, 'tinyagent/models_dev'
  autoload :Session, 'tinyagent/session'
  autoload :Settings, 'tinyagent/settings'
  autoload :TokenUsage, 'tinyagent/token_usage'
  autoload :Tool, 'tinyagent/tool'
  autoload :ToolDefinitions, 'tinyagent/tool_definitions'
  autoload :ThreadItem, 'tinyagent/thread_item'
  autoload :ToolCall, 'tinyagent/tool_call'
  autoload :Tui, 'tinyagent/tui'
  autoload :Thread, 'tinyagent/thread'

  extend Settings::Accessor

  DB = Sequel.sqlite
  Sequel::Model.db = DB

  # Prevent Sequel from inferring table name "models" at class definition time
  # @rbs skip
  Model = Class.new(Sequel::Model)
  Model.def_Model(self)

  # @rbs!
  #   class Model < Sequel::Model
  #   end
end

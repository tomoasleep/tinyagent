# frozen_string_literal: true

require 'json'
require 'sequel'

require 'tinyagent/version'

module Tinyagent
  class Error < StandardError; end

  autoload :Agent, 'tinyagent/agent'
  autoload :CompletionLoop, 'tinyagent/completion_loop'
  autoload :HttpMcpClient, 'tinyagent/http_mcp_client'
  autoload :LLM, 'tinyagent/llm'
  autoload :McpClients, 'tinyagent/mcp_clients'
  autoload :Settings, 'tinyagent/settings'
  autoload :TokenUsage, 'tinyagent/token_usage'
  autoload :Tool, 'tinyagent/tool'
  autoload :ToolDefinitions, 'tinyagent/tool_definitions'

  extend Settings::Accessor

  Model = Class.new(Sequel::Model)
  Model.def_Model(self)
  DB = Model.db = Sequel.sqlite

  Sequel.extension :migration
  migrations_dir = File.join(File.dirname(__FILE__), 'tinyagent', 'migrations')
  Sequel::Migrator.run(DB, migrations_dir)

  require 'tinyagent/thread_item'
  require 'tinyagent/message'
  require 'tinyagent/tool_call'
  require 'tinyagent/thread'
  require 'tinyagent/session'
end

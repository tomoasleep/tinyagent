# frozen_string_literal: true

module Tinyagent
  # Manages multiple MCP (Model Context Protocol) clients
  class McpClients
    attr_reader :clients #: Array[untyped]

    # @rbs clients: Array[untyped]
    def initialize(clients) #: void
      @clients = clients
    end

    def available_tools #: Array[Tool]
      clients.flat_map do |client|
        tool_defs = client.list_tools
        tool_defs.map do |tool_def|
          tool_name = "mcp_#{client.mcp_name}__#{tool_def['name']}"
          Tool.new(
            name: tool_name,
            title: tool_def['title'] || '',
            description: tool_def['description'] || '',
            input_schema: tool_def['inputSchema']
          ) do |params|
            client.call_tool(tool_def['name'], params).to_json
          end
        end
      rescue HttpMcpClient::Error => e
        warn "Failed to list tools for MCP client: #{e.message}"
        []
      end
    end

    def any? #: bool
      @clients.any?
    end
  end
end

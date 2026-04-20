# frozen_string_literal: true

module Tinyagent
  # Manage MCP configurations for a specific user.
  class UserMcpConfigurations < UserAssociations #[McpConfiguration]
    self.association_key = :mcp_configurations

    # @rbs mcp_configuration: McpConfiguration:
    def add(mcp_configuration) #: void
      store(mcp_configuration, key: mcp_configuration.name)
    end
  end
end

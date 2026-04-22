# frozen_string_literal: true

module Tinyagent
  # Manage thread-specific data.
  class Thread < Model
    one_to_many :thread_item
    many_to_one :session

    def tools #: Array[Tool]
      [
        *McpClients.for_thread(thread:).available_tools,
        *ToolDefinitions.for_thread(thread:).map(&:to_tool)
      ]
    end
  end
end

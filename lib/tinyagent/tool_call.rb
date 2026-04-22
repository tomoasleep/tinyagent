# frozen_string_literal: true

module Tinyagent
  # Save MCP configuration details.
  class ToolCall < Model
    many_to_one :message
  end
end

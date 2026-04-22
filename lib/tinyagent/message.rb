# frozen_string_literal: true

module Tinyagent
  # Save MCP configuration details.
  class Message < ThreadItem
    plugin :enum

    enum :role_id, system: 1, user: 2, assistant: 3

    one_to_many :tool_calls
  end
end

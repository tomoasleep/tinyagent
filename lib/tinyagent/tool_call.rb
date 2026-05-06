# frozen_string_literal: true

module Tinyagent
  # Record of a tool call invocation.
  class ToolCall < Model
    many_to_one :message

    def parsed_arguments #: untyped?
      return nil unless arguments

      JSON.parse(arguments || '{}')
    end
  end
end

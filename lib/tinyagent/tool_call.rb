# frozen_string_literal: true

module Tinyagent
  class ToolCall < Model
    many_to_one :message

    def parsed_arguments
      return nil unless arguments

      JSON.parse(arguments)
    end
  end
end

# frozen_string_literal: true

module Tinyagent
  module LLM
    # LLM response with optional tool call details.
    class Response < Data.define(
      :message,        #: Message
      :tool,           #: Tinyagent::Tool?
      :tool_call_id,   #: String?
      :tool_arguments  #: Hash[String, untyped]?
    )
      def call_tool #: String?
        tool&.call(tool_arguments || {})
      end
    end
  end
end

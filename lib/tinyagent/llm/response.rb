# frozen_string_literal: true

module Tinyagent
  module LLM
    Response = Data.define(
      :message, #: Message
      :tool, #: Tinyagent::Tool?
      :tool_call_id, #: String?
      :tool_arguments #: Hash[String, untyped]?
    )

    class Response
      def call_tool
        tool&.call(tool_arguments)
      end
    end
  end
end

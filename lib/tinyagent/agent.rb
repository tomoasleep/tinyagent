# frozen_string_literal: true

module Tinyagent
  # Orchestrate LLM completion with tool calling.
  class Agent
    attr_reader :llm #: LLM::OpenAI
    attr_reader :messages #: Array[Message]
    attr_reader :tools #: Array[Tool]

    # @rbs llm: LLM::OpenAI
    # @rbs messages: Array[Message]
    # @rbs tools: Array[Tool]
    def initialize(
      llm:,
      messages: [],
      tools: []
    ) #: void
      @llm = llm
      @messages = messages
      @tools = tools
    end

    def complete(&) #: Response
      loop do
        response = llm.complete(
          messages:,
          tools:
        )
        on_response(response, &)
        on_new_message(response.message, &)

        if response.tool
          on_tool_call(tool: response.tool, tool_arguments: response.tool_arguments, &)
          messages << response.message

          tool_response = response.call_tool || 'no return value'
          tool_response_message = Message.from_llm_response(
            tool: response.tool,
            tool_call_id: response.tool_call_id,
            tool_arguments: response.tool_arguments,
            tool_response:
          )
          on_tool_response(tool: response.tool, tool_response:, message: tool_response_message, &)
          messages << tool_response_message
        else
          messages << response.message

          return response
        end
      end
    end

    # @rbs message: Message
    # @rbs &callback: ? (Hash[Symbol, untyped]) -> void
    def on_new_message(message, &callback) #: void
      callback&.call({ type: :new_message, message: })
    end

    # @rbs tool: Tool
    # @rbs tool_arguments: Hash[String, untyped]
    # @rbs &callback: ? (Hash[Symbol, untyped]) -> void
    def on_tool_call(tool:, tool_arguments:, &callback) #: void
      callback&.call({ type: :tool_call, tool:, tool_arguments: })
    end

    # @rbs tool: Tool
    # @rbs tool_response: untyped
    # @rbs message: Message
    # @rbs &callback: ? (Hash[Symbol, untyped]) -> void
    def on_tool_response(tool:, tool_response:, message:, &callback) #: void
      callback&.call({ type: :tool_response, tool:, tool_response:, message: })
    end

    # @rbs response: Response
    # @rbs &callback: ? (Hash[Symbol, untyped]) -> void
    def on_response(response, &callback) #: void
      callback&.call({ type: :response, response: })
    end
  end
end

# frozen_string_literal: true

module Tinyagent
  # Chat message stored in a thread.
  class Message < ThreadItem
    ROLES = { system: 1, user: 2, assistant: 3, tool: 4 }.freeze
    ROLE_IDS = ROLES.invert.freeze

    one_to_many :tool_calls

    def role #: Symbol
      ROLE_IDS[role_id]
    end

    def tool_call? #: bool
      !tool_calls.empty?
    end

    def tool_call_id #: String?
      tool_calls.first&.api_id
    end

    def tool_name #: String?
      tool_calls.first&.name
    end

    def tool_arguments #: Hash[String, untyped]?
      tool_calls.first&.parsed_arguments
    end

    def token_usage #: TokenUsage?
      return nil unless token_usage_total_tokens
      return nil unless token_usage_prompt_tokens
      return nil unless token_usage_completion_tokens

      TokenUsage.new(
        prompt_tokens: token_usage_prompt_tokens || 0,
        completion_tokens: token_usage_completion_tokens || 0,
        total_tokens: token_usage_total_tokens || 0,
        token_limit: token_usage_token_limit
      )
    end

    def to_h #: Hash[Symbol, untyped]
      {
        role: role,
        content: content,
        tool_call_id: tool_call_id,
        tool_name: tool_name,
        tool_arguments: tool_arguments,
        token_usage: token_usage&.to_h
      }
    end

    # @rbs tool: Tool
    # @rbs tool_call_id: String
    # @rbs tool_arguments: Hash[String, untyped]
    # @rbs tool_response: String
    def self.from_llm_response(tool:, tool_call_id:, tool_arguments:, tool_response:) #: Message
      msg = new(
        role_id: ROLES[:tool],
        content: tool_response
      )
      msg.associate_tool_call(
        api_id: tool_call_id,
        name: tool.name,
        arguments: tool_arguments
      )
      msg
    end

    # @rbs api_id: String
    # @rbs name: String
    # @rbs arguments: Hash[String, untyped]
    def associate_tool_call(api_id:, name:, arguments:) #: ToolCall
      tc = ToolCall.new(
        api_id: api_id,
        name: name,
        arguments: arguments.to_json
      )
      tool_calls << tc
      tc
    end

    def before_create #: void
      self.type = 'Message'
      super
    end
  end
end

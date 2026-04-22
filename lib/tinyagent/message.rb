# frozen_string_literal: true

module Tinyagent
  class Message < ThreadItem
    ROLES = { system: 1, user: 2, assistant: 3, tool: 4 }.freeze
    ROLE_IDS = ROLES.invert.freeze

    one_to_many :tool_calls

    def role
      ROLE_IDS[role_id]
    end

    def tool_call?
      !tool_calls.empty?
    end

    def tool_call_id
      tool_calls.first&.api_id
    end

    def tool_name
      tool_calls.first&.name
    end

    def tool_arguments
      tool_calls.first&.parsed_arguments
    end

    def token_usage
      return nil unless token_usage_total_tokens

      TokenUsage.new(
        prompt_tokens: token_usage_prompt_tokens,
        completion_tokens: token_usage_completion_tokens,
        total_tokens: token_usage_total_tokens,
        token_limit: token_usage_token_limit
      )
    end

    def to_h
      {
        role: role,
        content: content,
        tool_call_id: tool_call_id,
        tool_name: tool_name,
        tool_arguments: tool_arguments,
        token_usage: token_usage&.to_h
      }
    end

    def self.from_llm_response(tool:, tool_call_id:, tool_arguments:, tool_response:)
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

    def associate_tool_call(api_id:, name:, arguments:)
      tc = ToolCall.new(
        api_id: api_id,
        name: name,
        arguments: arguments.to_json
      )
      tool_calls << tc
      tc
    end

    def before_create
      self.type = 'Message'
      super
    end
  end
end

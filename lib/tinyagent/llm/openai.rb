# frozen_string_literal: true

require 'openai'

module Tinyagent
  module LLM
    # OpenAI-compatible LLM client.
    class OpenAI
      autoload :Model, 'tinyagent/llm/openai/model'
      attr_reader :client #: OpenAI::Client
      attr_reader :model #: String

      # @rbs client: OpenAI::Client
      # @rbs model: String
      def initialize(client: nil, model: nil) #: void
        @client = client || build_default_client
        @model = model || ENV.fetch('OPENAI_MODEL', 'gpt-5-nano')
      end

      # @rbs @model_info: Model

      # @rbs %a{memorized}
      def model_info #: Model
        @model_info ||= Model.new(model)
      end

      # @rbs messages: Array[Message]
      # @rbs tools: Array[Tool]
      def complete(messages:, tools: []) #: Response
        openai_response = client.chat.completions.create(
          model:,
          messages: openai_messages_from_messages(messages), #: untyped
          tools: openai_tools_from_tools(tools)
        )

        to_response(openai_response:, tools:)
      end

      private

      def build_default_client #: OpenAI::Client
        opts = { api_key: ENV.fetch('OPENAI_API_KEY', nil) }
        base_url = ENV.fetch('OPENAI_BASE_URL', nil)
        opts[:base_url] = base_url if base_url
        ::OpenAI::Client.new(**opts)
      end

      # @rbs!
      #   type tool_call = {
      #     id: String,
      #     type: 'function',
      #     function: { name: String, arguments: String }
      #   }

      # @rbs!
      #   type system_message = { role: 'system', content: String }
      #   type user_message = { role: 'user', content: String }
      #   type assistant_message = { role: 'assistant', content: String, tool_calls: Array[tool_call]? }
      #   type tool_message = { role: 'tool', tool_call_id: String, content: String }
      #   type message = system_message | user_message | assistant_message | tool_message

      # @rbs messages: Array[Message]
      def openai_messages_from_messages(messages) #: Array[OpenAI::Models::Chat::chat_completion_message_param]
        messages.map do |message|
          case message.role
          when :system
            ::OpenAI::Models::Chat::ChatCompletionSystemMessageParam.new(
              role: :system, content: message.content || ''
            )
          when :user
            ::OpenAI::Models::Chat::ChatCompletionUserMessageParam.new(
              role: :user, content: message.content || ''
            )
          when :assistant
            if message.tool_call?
              tool_calls = [
                ::OpenAI::Models::Chat::ChatCompletionMessageFunctionToolCall.new(
                  id: message.tool_call_id || raise('tool_call_id is required for assistant tool call'),
                  type: :function,
                  function: ::OpenAI::Models::Chat::ChatCompletionMessageFunctionToolCall::Function.new(
                    name: message.tool_name || 'unknown_tool',
                    arguments: message.tool_arguments.to_json
                  )
                )
              ]
            end

            if tool_calls
              ::OpenAI::Models::Chat::ChatCompletionAssistantMessageParam.new(
                role: :assistant,
                content: message.content,
                tool_calls: tool_calls
              )
            else
              ::OpenAI::Models::Chat::ChatCompletionAssistantMessageParam.new(
                role: :assistant,
                content: message.content
              )
            end
          when :tool
            ::OpenAI::Models::Chat::ChatCompletionToolMessageParam.new(
              role: :tool,
              tool_call_id: message.tool_call_id || raise('tool_call_id is required for tool message'),
              content: message.content || ''
            )
          else
            raise "Unknown message role: #{message.role}"
          end
        end
      end

      # @rbs tools: Array[Tool]
      def openai_tools_from_tools(tools) #: Array[OpenAI::Models::Chat::chat_completion_tool]
        tools.map do |tool|
          ::OpenAI::Models::Chat::ChatCompletionFunctionTool.new(
            type: :function,
            function: ::OpenAI::FunctionDefinition.new(
              name: tool.name,
              description: tool.description,
              parameters: tool.input_schema || {
                type: 'object',
                properties: {}, #: Hash[untyped, untyped]
                required: [] #: Array[untyped]
              }
            )
          )
        end
      end

      # @rbs openai_response: OpenAI::Models::Chat::ChatCompletion
      # @rbs tools: Array[Tool]
      def to_response(openai_response:, tools:) #: Response
        choice = openai_response.choices.first
        tool_call = choice.message.tool_calls&.first

        token_usage = if openai_response.usage
                        TokenUsage.new(
                          prompt_tokens: openai_response.usage.prompt_tokens,
                          completion_tokens: openai_response.usage.completion_tokens,
                          total_tokens: openai_response.usage.total_tokens,
                          token_limit: model_info.token_limit
                        )
                      end

        if tool_call
          tool = tools.find do |t|
            if tool_call.type == :function
              function_name =
                tool_call #: OpenAI::Models::Chat::ChatCompletionMessageFunctionToolCall
                .function.name
              t.name == function_name
            else
              false
            end
          end
        end

        tool_arguments =
          if tool_call && tool_call.type == :function
            arguments =
              tool_call #: OpenAI::Models::Chat::ChatCompletionMessageFunctionToolCall
              .function.arguments

            JSON.parse(arguments)
          end

        msg = Message.new(
          role_id: Message::ROLES[:assistant],
          content: choice.message.content || '',
          token_usage_prompt_tokens: token_usage&.prompt_tokens,
          token_usage_completion_tokens: token_usage&.completion_tokens,
          token_usage_total_tokens: token_usage&.total_tokens,
          token_usage_token_limit: token_usage&.token_limit
        )

        if tool_call && tool_arguments
          msg.associate_tool_call(
            api_id: tool_call.id,
            name: tool&.name || 'unknown',
            arguments: tool_arguments || {}
          )
        end

        Response.new(
          message: msg,
          tool:,
          tool_call_id: tool_call&.id,
          tool_arguments:
        )
      end
    end
  end
end

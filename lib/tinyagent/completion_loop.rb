# frozen_string_literal: true

module Tinyagent
  class CompletionLoop
    attr_reader :thread #: Thread

    # @rbs thread: Thread
    def initialize(thread:)
      @thread = thread
    end

    def llm
      @llm ||= LLM::OpenAI.new
    end

    def completion_loop
      thread.refresh
      agent.complete do |event|
        case event[:type]
        when :new_message
          thread.add_message(
            role: event[:message].role,
            content: event[:message].content
          )
        when :tool_call
          # Tool calls are logged via events if needed
        when :tool_response
          msg = event[:message]
          thread.add_message(
            role: msg.role,
            content: msg.content
          )
          if msg.tool_calls.any?
            msg.tool_calls.each do |tc|
              Tinyagent::ToolCall.create(
                message_id: thread.messages.last.id,
                api_id: tc.api_id,
                name: tc.name,
                arguments: tc.arguments
              )
            end
          end
        end
      end

      thread.compact(llm:) if thread.over_auto_compact_threshold?
    rescue StandardError => e
      if ENV['DEBUG']
        warn e.full_message
      else
        warn e.message
      end
    end

    def agent
      Agent.new(
        llm:,
        messages: thread.messages,
        tools:
      )
    end

    def tools
      thread.tools
    end
  end
end

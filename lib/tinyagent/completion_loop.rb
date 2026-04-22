# frozen_string_literal: true

module Tinyagent
  # Chat action for Tinyagent
  class CompletionLoop
    attr_reader :thread #: Thread
    attr_reader :llm #: LLM::OpenAI

    # @rbs thread: Thread
    def initialize(thread:)
      @thread = thread
      @llm = LLM::OpenAI.new
    end

    # @rbs return: void
    def completion_loop
      agent.complete do |event|
        case event[:type]
        when :new_message
          chat_thread.messages << event[:message]
          message.reply(event[:message].content) if event[:message].content.length.positive?

          chat_thread.messages.compact(llm:) if chat_thread.messages.over_auto_compact_threshold?
        when :tool_call
          message.reply(indent_with_quotation("Calling tool #{event[:tool].name} with arguments #{truncate(event[:tool_arguments]&.to_json, max: 100)}")) unless event[:tool].silent?
        when :tool_response
          chat_thread.messages << event[:message]
          message.reply(indent_with_quotation("Tool response: #{truncate(event[:tool_response], max: 100)}")) unless event[:tool].silent?
        end
      end
    rescue StandardError => e
      if ENV['DEBUG']
        message.reply("エラーが発生しました: #{e.full_message}")
      else
        message.reply("エラーが発生しました: #{e.message}")
      end
    end

    def agent #: Agent
      Agent.new(
        llm:,
        messages:,
        tools:
      )
    end

    def tools #: Array[Tool]
      @tools ||= thread.tools
    end

    def messages = thread.messages #: Array[Message]
  end
end

# frozen_string_literal: true

module Tinyagent
  # Conversation thread with message history.
  class Thread < Model
    one_to_many :thread_items
    many_to_one :session

    one_to_many :messages

    def messages_dataset #: untyped
      super.order(:id)
    end

    # @rbs role: Symbol
    # @rbs content: String
    # @rbs **opts: untyped
    def add_message(role:, content:, **opts) #: Message
      Message.create(
        thread_id: id,
        role_id: Message::ROLES[role],
        content: content,
        **opts
      )
    end

    def clear #: void
      messages_dataset.all.each do |msg|
        msg.tool_calls.each(&:destroy)
        msg.destroy
      end
    end

    def over_auto_compact_threshold? #: bool
      !!token_usage&.over_auto_compact_threshold?
    end

    def token_usage #: TokenUsage?
      messages_dataset.reverse(:id).all.find(&:token_usage)&.token_usage
    end

    # @rbs llm: LLM::OpenAI
    def compact(llm:) #: void
      msgs = messages_dataset.all
      return if msgs.empty?

      last_assistant_message = msgs.reverse.find { |m| m.role == :assistant }

      summary = summarize(llm:)

      clear
      add_message(role: :system, content: "Previous conversation summary: #{summary}")
      add_message(role: :assistant, content: last_assistant_message&.content || '') if last_assistant_message&.tool_call?
    end

    # @rbs llm: LLM::OpenAI
    def summarize(llm:) #: String
      msgs = messages_dataset.all
      summary_prompt = Message.new(
        role_id: Message::ROLES[:system],
        content: <<~TEXT
          Please summarize the following conversation in a concise manner, capturing the key topics, decisions, and context that would be helpful for continuing the conversation:
        TEXT
      )

      response = llm.complete(messages: [summary_prompt, *msgs])
      response.message.content || ''
    end

    def tools #: Array[Tool]
      []
    end
  end
end

# frozen_string_literal: true

module Tinyagent
  # Conversation thread with message history.
  class Thread < Model
    one_to_many :thread_items
    many_to_one :session

    one_to_many :messages

    def messages_dataset
      super.order(:id)
    end

    def add_message(role:, content:, **opts)
      Message.create(
        thread_id: id,
        role_id: Message::ROLES[role],
        content: content,
        **opts
      )
    end

    def clear
      messages.each do |msg|
        msg.tool_calls.each(&:destroy)
        msg.destroy
      end
    end

    def over_auto_compact_threshold?
      !!token_usage&.over_auto_compact_threshold?
    end

    def token_usage
      messages.reverse_each.find(&:token_usage)&.token_usage
    end

    def compact(llm:)
      msgs = messages
      return if msgs.empty?

      last_assistant_message = msgs.reverse.find { |m| m.role == :assistant }

      summary = summarize(llm:)

      clear
      add_message(role: :system, content: "Previous conversation summary: #{summary}")
      add_message(role: :assistant, content: last_assistant_message.content) if last_assistant_message&.tool_call?
    end

    def summarize(llm:)
      summary_prompt = Message.new(
        role_id: Message::ROLES[:system],
        content: <<~TEXT
          Please summarize the following conversation in a concise manner, capturing the key topics, decisions, and context that would be helpful for continuing the conversation:
        TEXT
      )

      response = llm.complete(messages: [summary_prompt, *messages])
      response.message.content
    end

    def tools
      []
    end
  end
end

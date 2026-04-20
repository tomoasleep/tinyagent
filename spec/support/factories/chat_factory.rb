# frozen_string_literal: true

module ChatFactory
  include DatabaseFactory

  def create_chat_thread(database:, id: 'thread123', messages: [])
    chat_thread = database.chat_thread(id)

    messages.each do |message|
      chat_message = if message.is_a?(Tinyagent::ChatMessage)
                       message
                     else
                       Tinyagent::ChatMessage.new(**message)
                     end
      chat_thread.messages << chat_message
    end

    chat_thread
  end

  def create_conversation_history(database:, thread_id: 'conversation123')
    messages = [
      Tinyagent::ChatMessage.new(role: :system, content: 'You are a helpful assistant'),
      Tinyagent::ChatMessage.new(role: :user, content: 'Hello, how are you?'),
      Tinyagent::ChatMessage.new(role: :assistant,
                                 content: 'Hello! I\'m doing well, thank you for asking. How can I help you today?'),
      Tinyagent::ChatMessage.new(role: :user, content: 'What is the weather like?'),
      Tinyagent::ChatMessage.new(role: :assistant,
                                 content: 'I don\'t have access to real-time weather information.')
    ]

    create_chat_thread(database: database, id: thread_id, messages: messages)
  end

  def create_tool_conversation(database:, thread_id: 'tool_conversation123')
    messages = [
      Tinyagent::ChatMessage.new(role: :user, content: 'Calculate 2 + 2'),
      Tinyagent::ChatMessage.new(
        role: :assistant,
        content: nil,
        tool_call_id: 'call_123',
        tool_name: 'calculator',
        tool_arguments: { expression: '2 + 2' }
      ),
      Tinyagent::ChatMessage.new(
        role: :tool,
        content: '4',
        tool_call_id: 'call_123'
      ),
      Tinyagent::ChatMessage.new(role: :assistant, content: 'The result is 4.')
    ]

    create_chat_thread(database: database, id: thread_id, messages: messages)
  end
end

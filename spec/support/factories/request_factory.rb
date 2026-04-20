# frozen_string_literal: true

module RequestFactory
  include DatabaseFactory
  include MessageFactory

  def create_request(body:, from: 'user1', from_name: 'User1')
    message = create_message(body: body, from: from, from_name: from_name)
    database = Tinyagent::Database.new(message.robot.brain)

    Tinyagent::Request.new(
      message: message,
      chat_thread: database.chat_thread(from)
    )
  end
end

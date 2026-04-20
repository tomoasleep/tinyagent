# frozen_string_literal: true

module Tinyagent
  Request = Data.define(
    :message, #: _Message
    :chat_thread #: Tinyagent::ChatThread
  )

  # Request for chat action from user.
  class Request
    def message_body #: String
      message[:body]
    end
  end
end

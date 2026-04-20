# frozen_string_literal: true

module Tinyagent
  # Manage thread-specific data.
  class ChatThread
    attr_reader :database #: Tinyagent::Database
    attr_reader :id #: String

    class << self
      def find_or_create(database:, id:) #: ChatThread
        new(database: database, id: id)
      end
    end

    def initialize(database:, id:)
      @database = database
      @id = id
    end

    # @rbs %a{memorized}
    def messages #: ChatThreadMessages
      @messages ||= ChatThreadMessages.new(database: database, chat_thread_id: id)
    end

    def clear #: void
      messages.clear
    end
  end
end

# frozen_string_literal: true

module Tinyagent
  module Actions
    # Base class for actions.
    # @abstract
    class Base
      attr_reader :message #: _Message

      # @rbs message: _Message
      # @rbs return: void
      def self.call(message)
        new(message).call
      end

      # @rbs return: void
      def call
        raise NotImplementedError
      end

      def initialize(message)
        @message = message
      end

      # @rbs %a{memorized}
      def database #: Tinyagent::Database
        @database ||= Tinyagent::Database.new(message.robot.brain)
      end

      # @rbs %a{memorized}
      def user #: Tinyagent::User
        @user ||= database.user(message.from_name)
      end

      # @rbs %a{memorized}
      def chat_thread #: Tinyagent::ChatThread
        @chat_thread ||= database.chat_thread(thread_id)
      end

      private

      def thread_id #: String
        if message.respond_to?(:original) && message.original&.dig(:thread_ts)
          message.original[:thread_ts]
        else
          message.from || 'default'
        end
      end
    end
  end
end

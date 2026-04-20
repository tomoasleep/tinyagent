# frozen_string_literal: true

module Tinyagent
  module Commands
    # Base class for commands.
    # @abstract
    class Base
      attr_reader :request #: Request

      # @rbs request: Request
      def initialize(request:)
        @request = request

        super()
      end

      def message #: _Message
        request.message
      end

      def chat_thread #: Tinyagent::ChatThread
        request.chat_thread
      end

      # @rbs *args: untyped
      # @rbs return: untyped
      def call(*args)
        raise NotImplementedError
      end

      # @rbs commandline: String
      # @rbs return: boolish
      # @abstract
      def match?(commandline)
        raise NotImplementedError
      end
    end
  end
end

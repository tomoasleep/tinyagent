# frozen_string_literal: true

module Tinyagent
  module LLM
    # Represents an LLM model with metadata like context limit and tool support.
    class Model
      attr_reader :name #: String
      attr_reader :context_limit #: Integer?
      attr_reader :supports_tools #: boolish

      # @rbs name: String
      # @rbs context_limit: Integer?
      # @rbs supports_tools: boolish
      def initialize(name:, context_limit: nil, supports_tools: false) #: void
        @name = name
        @context_limit = context_limit
        @supports_tools = supports_tools
      end

      def token_limit #: Integer
        context_limit || Tinyagent.settings.max_tokens || 128_000
      end

      def supports_tools? #: boolish
        supports_tools
      end
    end
  end
end

# frozen_string_literal: true

module Tinyagent
  module LLM
    # Represents an LLM model with metadata like context limit and tool support.
    class Model
      attr_reader :name, :context_limit, :supports_tools

      def initialize(name:, context_limit: nil, supports_tools: false)
        @name = name
        @context_limit = context_limit
        @supports_tools = supports_tools
      end

      def token_limit
        context_limit || Tinyagent.settings.max_tokens || 128_000
      end

      def supports_tools?
        supports_tools
      end
    end
  end
end

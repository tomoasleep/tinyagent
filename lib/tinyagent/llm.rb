# frozen_string_literal: true

module Tinyagent
  # LLM-related backends and its utilities.
  module LLM
    autoload :OpenAI, 'tinyagent/llm/openai'
    autoload :Response, 'tinyagent/llm/response'
  end
end

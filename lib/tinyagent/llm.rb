# frozen_string_literal: true

module Tinyagent
  # LLM-related backends and its utilities.
  module LLM
    autoload :Model, 'tinyagent/llm/model'
    autoload :OpenAI, 'tinyagent/llm/openai'
    autoload :Provider, 'tinyagent/llm/provider'
    autoload :Response, 'tinyagent/llm/response'
  end
end

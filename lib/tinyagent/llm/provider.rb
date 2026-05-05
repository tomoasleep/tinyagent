# frozen_string_literal: true

require 'openai'

module Tinyagent
  module LLM
    # Represents an LLM provider with API credentials and client building.
    class Provider
      attr_reader :id, :name, :base_url, :api_key_env

      def initialize(id:, name:, base_url: nil, api_key: nil, api_key_env: nil)
        @id = id
        @name = name
        @base_url = base_url
        @api_key = api_key
        @api_key_env = api_key_env
      end

      def resolved_api_key
        @api_key || (api_key_env ? ENV.fetch(api_key_env, nil) : nil)
      end

      def build_client
        opts = { api_key: resolved_api_key }
        opts[:base_url] = base_url if base_url
        ::OpenAI::Client.new(**opts)
      end

      def available_models(catalog: ModelsDev::Catalog.new)
        catalog.models_for(id)
      end
    end
  end
end

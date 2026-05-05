# frozen_string_literal: true

require 'openai'

module Tinyagent
  module LLM
    # Represents an LLM provider with API credentials and client building.
    class Provider
      attr_reader :id #: Symbol
      attr_reader :name #: String
      attr_reader :base_url #: String?
      attr_reader :api_key_env #: String?

      # @rbs @api_key: String?

      # @rbs id: Symbol
      # @rbs name: String
      # @rbs base_url: String?
      # @rbs api_key: String?
      # @rbs api_key_env: String?
      def initialize(id:, name:, base_url: nil, api_key: nil, api_key_env: nil) #: void
        @id = id
        @name = name
        @base_url = base_url
        @api_key = api_key
        @api_key_env = api_key_env
      end

      def resolved_api_key #: String?
        @api_key || (api_key_env ? ENV.fetch(api_key_env, nil) : nil)
      end

      def build_client #: OpenAI::Client
        opts = { api_key: resolved_api_key }
        opts[:base_url] = base_url if base_url
        ::OpenAI::Client.new(**opts)
      end

      # @rbs catalog: ModelsDev::Catalog
      def available_models(catalog: ModelsDev::Catalog.new) #: Hash[String, untyped]
        catalog.models_for(id)
      end
    end
  end
end

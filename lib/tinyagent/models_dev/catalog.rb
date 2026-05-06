# frozen_string_literal: true

require 'json'
require 'net/http'
require 'fileutils'

module Tinyagent
  module ModelsDev
    # Fetches and caches the models.dev API catalog.
    class Catalog
      API_URL = 'https://models.dev/api.json'
      DEFAULT_TTL = 86_400

      attr_accessor :cache_path #: String

      # @rbs cache_path: String
      def initialize(cache_path: default_cache_path) #: void
        @cache_path = cache_path
      end

      def fetch #: Hash[String, untyped]
        uri = URI(API_URL)
        response = Net::HTTP.get_response(uri)
        raise "Failed to fetch catalog: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      end

      # @rbs ttl: Integer
      def cached_fetch(ttl: DEFAULT_TTL) #: Hash[String, untyped]
        if fresh_cache?(ttl)
          cache = JSON.parse(File.read(cache_path))
          return cache['data']
        end

        data = fetch
        write_cache(data)
        data
      end

      def providers #: Hash[String, untyped]
        cached_fetch
      end

      def openai_compatible_providers #: Hash[String, untyped]
        providers.select do |_id, provider|
          npm = provider['npm'].to_s
          npm.include?('openai-compatible')
        end
      end

      # @rbs provider_id: Symbol | String
      def models_for(provider_id) #: Hash[String, untyped]
        provider = providers[provider_id.to_s]
        return {} unless provider

        provider.fetch('models', _ = {})
      end

      private

      def default_cache_path #: String
        File.expand_path('~/.tinyagent/cache/models.dev.json')
      end

      # @rbs ttl: Integer
      def fresh_cache?(ttl) #: bool
        return false unless File.exist?(cache_path)

        cache = JSON.parse(File.read(cache_path))
        fetched_at = cache['fetched_at'].to_i
        Time.now.to_i - fetched_at < ttl
      rescue JSON::ParserError
        false
      end

      # @rbs data: Hash[String, untyped]
      def write_cache(data) #: void
        FileUtils.mkdir_p(File.dirname(cache_path))
        File.write(cache_path, JSON.dump({ 'data' => data, 'fetched_at' => Time.now.to_i }))
      end
    end
  end
end

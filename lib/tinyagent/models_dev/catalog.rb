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

      attr_accessor :cache_path

      def initialize(cache_path: default_cache_path)
        @cache_path = cache_path
      end

      def fetch
        uri = URI(API_URL)
        response = Net::HTTP.get_response(uri)
        raise "Failed to fetch catalog: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      end

      def cached_fetch(ttl: DEFAULT_TTL)
        if fresh_cache?(ttl)
          cache = JSON.parse(File.read(cache_path))
          return cache['data']
        end

        data = fetch
        write_cache(data)
        data
      end

      def providers
        cached_fetch
      end

      def openai_compatible_providers
        providers.select do |_id, provider|
          npm = provider['npm'].to_s
          npm.include?('openai-compatible')
        end
      end

      def models_for(provider_id)
        provider = providers[provider_id.to_s]
        return {} unless provider

        provider.fetch('models', {})
      end

      private

      def default_cache_path
        File.expand_path('~/.tinyagent/cache/models.dev.json')
      end

      def fresh_cache?(ttl)
        return false unless File.exist?(cache_path)

        cache = JSON.parse(File.read(cache_path))
        fetched_at = cache['fetched_at'].to_i
        Time.now.to_i - fetched_at < ttl
      rescue JSON::ParserError
        false
      end

      def write_cache(data)
        FileUtils.mkdir_p(File.dirname(cache_path))
        File.write(cache_path, JSON.dump({ 'data' => data, 'fetched_at' => Time.now.to_i }))
      end
    end
  end
end

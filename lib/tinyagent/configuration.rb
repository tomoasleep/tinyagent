# frozen_string_literal: true

require 'json'
require 'fileutils'

module Tinyagent
  # Manages persistent configuration for providers and models via JSON files.
  class Configuration
    DEFAULT_DATA_PATH = File.expand_path('~/.tinyagent/tinyagent.json')
    DEFAULT_CONFIG_PATH = File.expand_path('~/.config/tinyagent/tinyagent.json')

    attr_reader :data_path #: String
    attr_reader :config_path #: String

    # @rbs data_path: String
    # @rbs config_path: String
    def initialize(data_path: DEFAULT_DATA_PATH, config_path: DEFAULT_CONFIG_PATH) #: void
      @data_path = data_path
      @config_path = config_path
    end

    def current_provider #: String
      data['current_provider'] || 'openai'
    end

    # @rbs provider: String
    def current_provider=(provider) #: void
      update_data('current_provider' => provider)
    end

    def current_model #: String
      data['current_model'] || ENV.fetch('OPENAI_MODEL', 'gpt-5-nano')
    end

    # @rbs model: String
    def current_model=(model) #: void
      update_data('current_model' => model)
    end

    # @rbs provider_id: Symbol | String
    def provider_config(provider_id) #: Hash[String, untyped]
      config.fetch('providers', {}).fetch(provider_id.to_s, {})
    end

    # @rbs provider_id: Symbol | String
    # @rbs api_key: String?
    # @rbs base_url: String?
    def set_provider_config(provider_id, api_key: nil, base_url: nil) #: void
      new_config = config
      new_config['providers'] ||= {}
      new_config['providers'][provider_id.to_s] = {
        'api_key' => api_key,
        'base_url' => base_url
      }.compact
      write_config(new_config)
    end

    private

    def data #: Hash[String, untyped]
      read_json(data_path)
    end

    def config #: Hash[String, untyped]
      read_json(config_path)
    end

    # @rbs updates: Hash[String, untyped]
    def update_data(updates) #: void
      new_data = data.merge(updates)
      write_json(data_path, new_data)
    end

    # @rbs new_config: Hash[String, untyped]
    def write_config(new_config) #: void
      write_json(config_path, new_config)
    end

    # @rbs path: String
    def read_json(path) #: Hash[String, untyped]
      return {} unless File.exist?(path)

      JSON.parse(File.read(path))
    rescue JSON::ParserError
      {}
    end

    # @rbs path: String
    # @rbs content: Hash[String, untyped]
    def write_json(path, content) #: void
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, JSON.pretty_generate(content))
    end
  end
end

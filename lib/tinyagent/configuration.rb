# frozen_string_literal: true

require 'json'
require 'fileutils'

module Tinyagent
  # Manages persistent configuration for providers and models via JSON files.
  class Configuration
    DEFAULT_DATA_PATH = File.expand_path('~/.tinyagent/tinyagent.json')
    DEFAULT_CONFIG_PATH = File.expand_path('~/.config/tinyagent/tinyagent.json')

    attr_reader :data_path, :config_path

    def initialize(data_path: DEFAULT_DATA_PATH, config_path: DEFAULT_CONFIG_PATH)
      @data_path = data_path
      @config_path = config_path
    end

    def current_provider
      data['current_provider'] || 'openai'
    end

    def current_provider=(provider)
      update_data('current_provider' => provider)
    end

    def current_model
      data['current_model'] || ENV.fetch('OPENAI_MODEL', 'gpt-5-nano')
    end

    def current_model=(model)
      update_data('current_model' => model)
    end

    def provider_config(provider_id)
      config.fetch('providers', {}).fetch(provider_id.to_s, {})
    end

    def set_provider_config(provider_id, api_key: nil, base_url: nil)
      new_config = config
      new_config['providers'] ||= {}
      new_config['providers'][provider_id.to_s] = {
        'api_key' => api_key,
        'base_url' => base_url
      }.compact
      write_config(new_config)
    end

    private

    def data
      read_json(data_path)
    end

    def config
      read_json(config_path)
    end

    def update_data(updates)
      new_data = data.merge(updates)
      write_json(data_path, new_data)
    end

    def write_config(new_config)
      write_json(config_path, new_config)
    end

    def read_json(path)
      return {} unless File.exist?(path)

      JSON.parse(File.read(path))
    rescue JSON::ParserError
      {}
    end

    def write_json(path, content)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, JSON.pretty_generate(content))
    end
  end
end

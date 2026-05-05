# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'fileutils'
require 'tmpdir'

RSpec.describe Tinyagent::Configuration do
  let(:data_dir) { Dir.mktmpdir }
  let(:config_dir) { Dir.mktmpdir }
  let(:data_path) { File.join(data_dir, 'tinyagent.json') }
  let(:config_path) { File.join(config_dir, 'tinyagent.json') }

  let(:configuration) do
    described_class.new(data_path:, config_path:)
  end

  after do
    FileUtils.rm_rf(data_dir)
    FileUtils.rm_rf(config_dir)
  end

  describe '#current_provider' do
    it 'returns the saved provider' do
      File.write(data_path, JSON.dump({ 'current_provider' => 'openrouter' }))
      expect(configuration.current_provider).to eq('openrouter')
    end

    it 'falls back to openai when not set' do
      expect(configuration.current_provider).to eq('openai')
    end
  end

  describe '#current_provider=' do
    it 'saves the provider to data file' do
      configuration.current_provider = 'openrouter'
      expect(JSON.parse(File.read(data_path))['current_provider']).to eq('openrouter')
    end
  end

  describe '#current_model' do
    it 'returns the saved model' do
      File.write(data_path, JSON.dump({ 'current_model' => 'gpt-4o' }))
      expect(configuration.current_model).to eq('gpt-4o')
    end

    it 'falls back to gpt-5-nano when not set' do
      expect(configuration.current_model).to eq('gpt-5-nano')
    end
  end

  describe '#current_model=' do
    it 'saves the model to data file' do
      configuration.current_model = 'gpt-4o'
      expect(JSON.parse(File.read(data_path))['current_model']).to eq('gpt-4o')
    end
  end

  describe '#provider_config' do
    it 'returns config for the given provider', :aggregate_failures do
      File.write(config_path, JSON.dump({
                                          'providers' => {
                                            'openai' => { 'api_key' => 'sk-test', 'base_url' => 'https://custom.openai.com' }
                                          }
                                        }))
      config = configuration.provider_config('openai')
      expect(config['api_key']).to eq('sk-test')
      expect(config['base_url']).to eq('https://custom.openai.com')
    end

    it 'returns empty hash for unknown provider' do
      expect(configuration.provider_config('unknown')).to eq({})
    end
  end

  describe '#set_provider_config' do
    it 'saves provider config to config file', :aggregate_failures do
      configuration.set_provider_config('openai', api_key: 'sk-new', base_url: 'https://api.openai.com/v1')
      config = JSON.parse(File.read(config_path))
      expect(config['providers']['openai']['api_key']).to eq('sk-new')
      expect(config['providers']['openai']['base_url']).to eq('https://api.openai.com/v1')
    end
  end
end

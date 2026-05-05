# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'fileutils'
require 'tmpdir'

RSpec.describe Tinyagent::ModelsDev::Catalog do
  let(:cache_dir) { Dir.mktmpdir }
  let(:cache_path) { File.join(cache_dir, 'models.dev.json') }
  let(:catalog) { described_class.new(cache_path:) }

  let(:stub_response) do
    {
      'openai' => {
        'id' => 'openai',
        'name' => 'OpenAI',
        'env' => ['OPENAI_API_KEY'],
        'npm' => '@ai-sdk/openai',
        'api' => 'https://api.openai.com/v1',
        'models' => {
          'gpt-4o' => {
            'id' => 'gpt-4o',
            'name' => 'GPT-4o',
            'limit' => { 'context' => 128_000 },
            'tool_call' => true
          }
        }
      },
      'anthropic' => {
        'id' => 'anthropic',
        'name' => 'Anthropic',
        'env' => ['ANTHROPIC_API_KEY'],
        'npm' => '@ai-sdk/anthropic',
        'models' => {
          'claude-3' => {
            'id' => 'claude-3',
            'name' => 'Claude 3',
            'limit' => { 'context' => 200_000 },
            'tool_call' => true
          }
        }
      },
      'openrouter' => {
        'id' => 'openrouter',
        'name' => 'OpenRouter',
        'env' => ['OPENROUTER_API_KEY'],
        'npm' => '@ai-sdk/openai-compatible',
        'api' => 'https://openrouter.ai/api/v1',
        'models' => {
          'mistral' => {
            'id' => 'mistral',
            'name' => 'Mistral',
            'limit' => { 'context' => 32_000 },
            'tool_call' => false
          }
        }
      }
    }
  end

  before do
    stub_request(:get, 'https://models.dev/api.json')
      .to_return(status: 200, body: stub_response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  after do
    FileUtils.rm_rf(cache_dir)
  end

  describe '#fetch' do
    it 'fetches and parses the catalog from models.dev' do
      result = catalog.fetch
      expect(result).to eq(stub_response)
    end
  end

  describe '#cached_fetch' do
    context 'when cache does not exist' do
      it 'fetches from API and writes cache', :aggregate_failures do
        result = catalog.cached_fetch
        expect(result).to eq(stub_response)
        expect(File).to exist(cache_path)
        expect(JSON.parse(File.read(cache_path))['data']).to eq(stub_response)
      end
    end

    context 'when cache exists and is fresh' do
      before do
        FileUtils.mkdir_p(File.dirname(cache_path))
        File.write(cache_path, JSON.dump({ 'data' => { 'cached' => true }, 'fetched_at' => Time.now.to_i }))
      end

      it 'returns cached data without hitting the API', :aggregate_failures do
        allow(catalog).to receive(:fetch)
        result = catalog.cached_fetch
        expect(result).to eq({ 'cached' => true })
        expect(catalog).not_to have_received(:fetch)
      end
    end

    context 'when cache exists but is stale' do
      before do
        FileUtils.mkdir_p(File.dirname(cache_path))
        File.write(cache_path, JSON.dump({ 'data' => { 'cached' => true }, 'fetched_at' => Time.now.to_i - 100_000 }))
      end

      it 'refetches from API' do
        result = catalog.cached_fetch
        expect(result).to eq(stub_response)
      end
    end
  end

  describe '#providers' do
    it 'returns all providers' do
      providers = catalog.providers
      expect(providers.keys).to contain_exactly('openai', 'anthropic', 'openrouter')
    end
  end

  describe '#openai_compatible_providers' do
    it 'returns only providers with openai-compatible npm package' do
      providers = catalog.openai_compatible_providers
      expect(providers.keys).to contain_exactly('openrouter')
    end
  end

  describe '#models_for' do
    it 'returns models for the given provider', :aggregate_failures do
      models = catalog.models_for('openai')
      expect(models.keys).to contain_exactly('gpt-4o')
      expect(models['gpt-4o']['name']).to eq('GPT-4o')
    end

    it 'returns empty hash for unknown provider' do
      expect(catalog.models_for('unknown')).to eq({})
    end
  end
end

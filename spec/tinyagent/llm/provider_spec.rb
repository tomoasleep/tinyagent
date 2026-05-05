# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tinyagent::LLM::Provider do
  let(:provider) do
    described_class.new(
      id: 'openrouter',
      name: 'OpenRouter',
      base_url: 'https://openrouter.ai/api/v1',
      api_key: 'sk-test',
      api_key_env: 'OPENROUTER_API_KEY'
    )
  end

  describe '#resolved_api_key' do
    it 'returns explicitly set api_key' do
      expect(provider.resolved_api_key).to eq('sk-test')
    end

    it 'falls back to environment variable when api_key is not set' do
      prov = described_class.new(id: 'openai', name: 'OpenAI', api_key_env: 'OPENAI_API_KEY')
      allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('sk-env')
      expect(prov.resolved_api_key).to eq('sk-env')
    end

    it 'returns nil when no api_key is available' do
      prov = described_class.new(id: 'x', name: 'X')
      expect(prov.resolved_api_key).to be_nil
    end
  end

  describe '#build_client' do
    it 'builds an OpenAI::Client with base_url and api_key' do
      client = provider.build_client
      expect(client).to be_a(OpenAI::Client)
    end
  end

  describe '#available_models' do
    let(:catalog) { instance_double(Tinyagent::ModelsDev::Catalog) }

    it 'fetches models for this provider from catalog', :aggregate_failures do
      allow(catalog).to receive(:models_for).with('openrouter').and_return(
        { 'mistral' => { 'name' => 'Mistral' } }
      )
      models = provider.available_models(catalog:)
      expect(models).to eq({ 'mistral' => { 'name' => 'Mistral' } })
      expect(catalog).to have_received(:models_for).with('openrouter')
    end
  end
end

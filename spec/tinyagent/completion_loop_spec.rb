# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tinyagent::CompletionLoop do
  include EnvMockHelper

  let(:thread) { Tinyagent::Thread.create }
  let(:configuration) { instance_double(Tinyagent::Configuration) }
  let(:catalog) { instance_double(Tinyagent::ModelsDev::Catalog) }

  let(:provider_data) do
    {
      'openrouter' => {
        'id' => 'openrouter',
        'name' => 'OpenRouter',
        'env' => ['OPENROUTER_API_KEY'],
        'api' => 'https://openrouter.ai/api/v1',
        'models' => {}
      }
    }
  end

  before do
    allow(Tinyagent::ModelsDev::Catalog).to receive(:new).and_return(catalog)
    allow(catalog).to receive(:openai_compatible_providers).and_return(provider_data)
  end

  describe '#llm' do
    context 'when provider is configured' do
      before do
        allow(configuration).to receive_messages(
          current_provider: 'openrouter',
          current_model: 'mistral'
        )
        allow(configuration).to receive(:provider_config).with('openrouter').and_return(
          { 'api_key' => 'sk-or', 'base_url' => 'https://custom.openrouter.ai' }
        )
      end

      it 'builds an LLM::OpenAI with the configured provider and model', :aggregate_failures do
        loop = described_class.new(thread:, configuration:)
        llm = loop.llm
        expect(llm).to be_a(Tinyagent::LLM::OpenAI)
        expect(llm.model).to eq('mistral')
        expect(llm.client).to be_a(OpenAI::Client)
      end
    end

    context 'when provider is not found in catalog' do
      before do
        stub_env(OPENAI_API_KEY: 'test-key')
        allow(configuration).to receive_messages(
          current_provider: 'unknown',
          current_model: 'gpt-5-nano'
        )
        allow(configuration).to receive(:provider_config).with('unknown').and_return({})
      end

      it 'falls back to default OpenAI provider', :aggregate_failures do
        loop = described_class.new(thread:, configuration:)
        llm = loop.llm
        expect(llm).to be_a(Tinyagent::LLM::OpenAI)
        expect(llm.model).to eq('gpt-5-nano')
      end
    end
  end
end

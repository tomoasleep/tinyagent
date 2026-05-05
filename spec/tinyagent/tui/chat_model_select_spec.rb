# frozen_string_literal: true

require 'spec_helper'
require 'bubbletea'
require 'bubbles'
require_relative '../../support/key_helper'

RSpec.describe Tinyagent::Tui::Chat do
  include KeyHelper

  let(:thread) { Tinyagent::Thread.create }
  let(:chat) { described_class.new(thread:) }
  let(:configuration) { instance_double(Tinyagent::Configuration) }
  let(:catalog) { instance_double(Tinyagent::ModelsDev::Catalog) }

  let(:provider_data) do
    {
      'openai' => {
        'id' => 'openai',
        'name' => 'OpenAI',
        'env' => ['OPENAI_API_KEY'],
        'api' => 'https://api.openai.com/v1',
        'models' => {
          'gpt-4o' => { 'id' => 'gpt-4o', 'name' => 'GPT-4o' }
        }
      },
      'openrouter' => {
        'id' => 'openrouter',
        'name' => 'OpenRouter',
        'env' => ['OPENROUTER_API_KEY'],
        'api' => 'https://openrouter.ai/api/v1',
        'models' => {
          'mistral' => { 'id' => 'mistral', 'name' => 'Mistral' }
        }
      }
    }
  end

  before do
    allow(Tinyagent::Configuration).to receive(:new).and_return(configuration)
    allow(Tinyagent::ModelsDev::Catalog).to receive(:new).and_return(catalog)
    allow(catalog).to receive(:openai_compatible_providers).and_return(provider_data)
    allow(catalog).to receive(:models_for).with('openai').and_return(provider_data['openai']['models'])
    allow(catalog).to receive(:models_for).with('openrouter').and_return(provider_data['openrouter']['models'])
    allow(configuration).to receive_messages(
      current_provider: 'openai',
      current_model: 'gpt-4o'
    )
    allow(configuration).to receive(:current_provider=)
    allow(configuration).to receive(:current_model=)
  end

  describe 'model selection' do
    before { chat.init }

    it 'opens provider selection on ctrl+m' do
      chat.update(key('ctrl+m'))
      expect(chat.state).to eq(:provider_select)
    end

    it 'closes provider selection on esc' do
      chat.update(key('ctrl+m'))
      chat.update(key('esc'))
      expect(chat.state).to eq(:idle)
    end

    it 'transitions to model selection after provider chosen' do
      chat.update(key('ctrl+m'))
      chat.update(key('enter'))
      expect(chat.state).to eq(:model_select)
    end

    it 'saves configuration and returns to idle after model chosen', :aggregate_failures do
      select_provider_and_model(chat)
      expect(configuration).to have_received(:current_provider=).with('openrouter')
      expect(configuration).to have_received(:current_model=).with('mistral')
    end

    it 'shows current provider/model in status bar' do
      view = chat.view
      expect(view).to include('openai/gpt-4o')
    end
  end
end

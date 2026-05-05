# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tinyagent::LLM::Model do
  describe '#token_limit' do
    it 'returns context_limit when available' do
      model = described_class.new(name: 'gpt-4o', context_limit: 128_000, supports_tools: true)
      expect(model.token_limit).to eq(128_000)
    end

    it 'falls back to settings.max_tokens when context_limit is nil' do
      allow(Tinyagent.settings).to receive(:max_tokens).and_return(64_000)
      model = described_class.new(name: 'custom-model')
      expect(model.token_limit).to eq(64_000)
    end

    it 'falls back to 128000 when no context_limit and no settings' do
      allow(Tinyagent.settings).to receive(:max_tokens).and_return(nil)
      model = described_class.new(name: 'unknown-model')
      expect(model.token_limit).to eq(128_000)
    end
  end

  describe '#supports_tools?' do
    it 'returns true when supports_tools is true' do
      model = described_class.new(name: 'gpt-4o', supports_tools: true)
      expect(model.supports_tools?).to be true
    end

    it 'returns false when supports_tools is false' do
      model = described_class.new(name: 'gpt-4o', supports_tools: false)
      expect(model.supports_tools?).to be false
    end

    it 'returns false by default' do
      model = described_class.new(name: 'gpt-4o')
      expect(model.supports_tools?).to be false
    end
  end
end

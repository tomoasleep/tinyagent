# frozen_string_literal: true

RSpec.describe Tinyagent::TokenUsage do
  describe '#initialize' do
    it 'stores token counts', :aggregate_failures do
      usage = described_class.new(
        prompt_tokens: 10,
        completion_tokens: 5,
        total_tokens: 15
      )
      expect(usage.prompt_tokens).to eq(10)
      expect(usage.completion_tokens).to eq(5)
      expect(usage.total_tokens).to eq(15)
    end

    it 'accepts optional token_limit' do
      usage = described_class.new(
        prompt_tokens: 10,
        completion_tokens: 5,
        total_tokens: 15,
        token_limit: 100
      )
      expect(usage.token_limit).to eq(100)
    end
  end

  describe '#usage_percentage' do
    it 'returns nil without token_limit' do
      usage = described_class.new(prompt_tokens: 10, completion_tokens: 5, total_tokens: 15)
      expect(usage.usage_percentage).to be_nil
    end

    it 'calculates percentage with token_limit' do
      usage = described_class.new(
        prompt_tokens: 40,
        completion_tokens: 10,
        total_tokens: 50,
        token_limit: 100
      )
      expect(usage.usage_percentage).to eq(50.0)
    end
  end

  describe '#over_auto_compact_threshold?' do
    include EnvMockHelper

    it 'returns false without token_limit' do
      usage = described_class.new(prompt_tokens: 10, completion_tokens: 5, total_tokens: 15)
      expect(usage.over_auto_compact_threshold?).to be false
    end

    it 'returns false when under threshold' do
      usage = described_class.new(
        prompt_tokens: 10,
        completion_tokens: 5,
        total_tokens: 15,
        token_limit: 100
      )
      expect(usage.over_auto_compact_threshold?).to be false
    end

    it 'returns true when at or over threshold' do
      usage = described_class.new(
        prompt_tokens: 40,
        completion_tokens: 10,
        total_tokens: 50,
        token_limit: 60
      )
      expect(usage.over_auto_compact_threshold?).to be true
    end

    it 'respects AUTO_COMPACT_THRESHOLD env variable' do
      stub_env('AUTO_COMPACT_THRESHOLD' => '50')
      usage = described_class.new(
        prompt_tokens: 10,
        completion_tokens: 5,
        total_tokens: 30,
        token_limit: 100
      )
      expect(usage.over_auto_compact_threshold?).to be false
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields', :aggregate_failures do
      usage = described_class.new(
        prompt_tokens: 10,
        completion_tokens: 5,
        total_tokens: 15,
        token_limit: 100
      )
      h = usage.to_h
      expect(h[:prompt_tokens]).to eq(10)
      expect(h[:completion_tokens]).to eq(5)
      expect(h[:total_tokens]).to eq(15)
      expect(h[:token_limit]).to eq(100)
    end
  end
end

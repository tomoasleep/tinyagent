# frozen_string_literal: true

RSpec.describe Tinyagent::CachedValue do
  describe '#initialize' do
    it 'stores data and expires_at' do
      time = Time.now + 600
      cached = described_class.new(data: 'test', expires_at: time)
      expect(cached.data).to eq('test')
      expect(cached.expires_at).to be_a(Time)
    end

    it 'parses string expires_at' do
      time_str = (Time.now + 600).rfc2822
      cached = described_class.new(data: 'test', expires_at: time_str)
      expect(cached.expires_at).to be_a(Time)
    end

    it 'rounds time to seconds' do
      time = Time.now + 600.123456
      cached = described_class.new(data: 'test', expires_at: time)
      expect(cached.expires_at.usec).to eq(0)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expires_at as rfc2822 and data' do
      time = Time.now + 600
      cached = described_class.new(data: { 'key' => 'value' }, expires_at: time)
      h = cached.to_h
      expect(h[:expires_at]).to eq(time.rfc2822)
      expect(h[:data]).to eq({ 'key' => 'value' })
    end
  end

  describe '#expired?' do
    it 'returns false when not expired' do
      cached = described_class.new(data: 'test', expires_at: Time.now + 600)
      expect(cached.expired?).to be false
    end

    it 'returns true when expired' do
      cached = described_class.new(data: 'test', expires_at: Time.now - 1)
      expect(cached.expired?).to be true
    end
  end

  describe '#valid?' do
    it 'returns true when not expired' do
      cached = described_class.new(data: 'test', expires_at: Time.now + 600)
      expect(cached.valid?).to be true
    end

    it 'returns false when expired' do
      cached = described_class.new(data: 'test', expires_at: Time.now - 1)
      expect(cached.valid?).to be false
    end
  end

  describe 'Recordable' do
    it 'includes record_type in to_h' do
      cached = described_class.new(data: 'test', expires_at: Time.now + 600)
      expect(cached.to_h[:record_type]).to eq(:mcp_cache)
    end
  end
end

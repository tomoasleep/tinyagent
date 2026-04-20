# frozen_string_literal: true

RSpec.describe Tinyagent::GlobalSettings do
  include DatabaseFactory

  let(:database) { create_database }

  describe '.find_or_create' do
    it 'creates a GlobalSettings instance' do
      settings = described_class.find_or_create(database: database)
      expect(settings).to be_a(described_class)
    end
  end

  describe '#initialize' do
    it 'stores the database' do
      settings = described_class.new(database: database)
      expect(settings.database).to eq(database)
    end
  end

  describe '#system_prompt' do
    it 'returns nil when not set' do
      settings = described_class.new(database: database)
      expect(settings.system_prompt).to be_nil
    end

    it 'returns the stored system prompt' do
      settings = described_class.new(database: database)
      settings.system_prompt = 'You are a helpful assistant'
      expect(settings.system_prompt).to eq('You are a helpful assistant')
    end
  end

  describe '#system_prompt=' do
    it 'stores the system prompt' do
      settings = described_class.new(database: database)
      settings.system_prompt = 'Be concise'
      expect(settings.system_prompt).to eq('Be concise')
    end

    it 'overwrites the system prompt' do
      settings = described_class.new(database: database)
      settings.system_prompt = 'First'
      settings.system_prompt = 'Second'
      expect(settings.system_prompt).to eq('Second')
    end
  end
end

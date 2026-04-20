# frozen_string_literal: true

RSpec.describe Tinyagent::ChatThread do
  include DatabaseFactory

  let(:database) { create_database }

  describe '.find_or_create' do
    it 'creates a new ChatThread' do
      thread = described_class.find_or_create(database: database, id: 'thread1')
      expect(thread).to be_a(described_class)
      expect(thread.id).to eq('thread1')
    end
  end

  describe '#initialize' do
    it 'sets database and id' do
      thread = described_class.new(database: database, id: 'test_thread')
      expect(thread.database).to eq(database)
      expect(thread.id).to eq('test_thread')
    end
  end

  describe '#messages' do
    it 'returns a ChatThreadMessages instance' do
      thread = described_class.new(database: database, id: 'thread1')
      expect(thread.messages).to be_a(Tinyagent::ChatThreadMessages)
    end

    it 'memoizes the messages' do
      thread = described_class.new(database: database, id: 'thread1')
      expect(thread.messages).to equal(thread.messages)
    end
  end

  describe '#clear' do
    it 'clears all messages' do
      thread = described_class.new(database: database, id: 'thread1')
      thread.messages << Tinyagent::ChatMessage.new(role: :user, content: 'Hello')
      expect(thread.messages.length).to eq(1)
      thread.clear
      expect(thread.messages.length).to eq(0)
    end
  end
end

# frozen_string_literal: true

RSpec.describe Tinyagent::ChatThreadMessages do
  include DatabaseFactory

  let(:database) { create_database }
  let(:chat_thread) { Tinyagent::ChatThread.new(database: database, id: 'thread1') }
  let(:messages) { chat_thread.messages }

  describe '#add' do
    it 'adds a message to the thread' do
      msg = Tinyagent::ChatMessage.new(role: :user, content: 'Hello')
      messages.add(msg)
      expect(messages.length).to eq(1)
    end

    it 'stores messages with sequential integer keys' do
      msg1 = Tinyagent::ChatMessage.new(role: :user, content: 'Hello')
      msg2 = Tinyagent::ChatMessage.new(role: :assistant, content: 'Hi')
      messages.add(msg1)
      messages.add(msg2)
      expect(messages.keys).to eq([0, 1])
    end
  end

  describe '#<<' do
    it 'is an alias for add' do
      msg = Tinyagent::ChatMessage.new(role: :user, content: 'Hello')
      messages << msg
      expect(messages.length).to eq(1)
    end
  end

  describe '#all_values' do
    it 'returns all messages' do
      msg1 = Tinyagent::ChatMessage.new(role: :user, content: 'Hello')
      msg2 = Tinyagent::ChatMessage.new(role: :assistant, content: 'Hi')
      messages << msg1
      messages << msg2
      expect(messages.all_values.length).to eq(2)
    end
  end

  describe '#token_usage' do
    it 'returns nil when no messages have token_usage' do
      messages << Tinyagent::ChatMessage.new(role: :user, content: 'Hello')
      expect(messages.token_usage).to be_nil
    end

    it 'returns the token_usage from the last message that has one' do
      usage1 = Tinyagent::TokenUsage.new(prompt_tokens: 10, completion_tokens: 5, total_tokens: 15)
      usage2 = Tinyagent::TokenUsage.new(prompt_tokens: 20, completion_tokens: 10, total_tokens: 30)

      messages << Tinyagent::ChatMessage.new(role: :user, content: 'Hello', token_usage: usage1)
      messages << Tinyagent::ChatMessage.new(role: :assistant, content: 'Hi', token_usage: usage2)

      expect(messages.token_usage).to eq(usage2)
    end
  end

  describe '#over_auto_compact_threshold?' do
    it 'returns false when no token usage' do
      messages << Tinyagent::ChatMessage.new(role: :user, content: 'Hello')
      expect(messages.over_auto_compact_threshold?).to be false
    end
  end

  describe '#empty?' do
    it 'returns true when no messages' do
      expect(messages.empty?).to be true
    end

    it 'returns false when there are messages' do
      messages << Tinyagent::ChatMessage.new(role: :user, content: 'Hello')
      expect(messages.empty?).to be false
    end
  end

  describe '#clear' do
    it 'removes all messages' do
      messages << Tinyagent::ChatMessage.new(role: :user, content: 'Hello')
      messages.clear
      expect(messages.empty?).to be true
    end
  end
end

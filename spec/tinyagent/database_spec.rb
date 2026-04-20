# frozen_string_literal: true

RSpec.describe Tinyagent::Database do
  include DatabaseFactory

  describe 'NAMESPACE' do
    it 'is :tinyagent' do
      expect(described_class::NAMESPACE).to eq(:tinyagent)
    end
  end

  describe '#initialize' do
    it 'accepts a brain object' do
      brain = create_brain
      db = described_class.new(brain)
      expect(db.brain).to eq(brain)
    end
  end

  describe '#data' do
    it 'returns a hash' do
      db = create_database
      expect(db.data).to be_a(Hash)
    end

    it 'returns data under the tinyagent namespace' do
      db = create_database
      expect(db.brain.data[described_class::NAMESPACE]).to eq(db.data)
    end

    it 'initializes empty hash when no data exists' do
      db = create_database
      expect(db.data).to eq({})
    end

    it 'preserves existing data' do
      db = create_database('users' => { 'u1' => { 'name' => 'test' } })
      expect(db.data).to eq('users' => { 'u1' => { 'name' => 'test' } })
    end
  end

  describe '#user' do
    it 'returns a User instance' do
      db = create_database
      user = db.user('test_user')
      expect(user).to be_a(Tinyagent::User)
    end

    it 'returns the same user for the same id' do
      db = create_database
      user1 = db.user('test_user')
      user2 = db.user('test_user')
      expect(user1.id).to eq(user2.id)
    end
  end

  describe '#chat_thread' do
    it 'returns a ChatThread instance' do
      db = create_database
      thread = db.chat_thread('thread1')
      expect(thread).to be_a(Tinyagent::ChatThread)
    end

    it 'returns the same thread for the same id' do
      db = create_database
      thread1 = db.chat_thread('thread1')
      thread2 = db.chat_thread('thread1')
      expect(thread1.id).to eq(thread2.id)
    end
  end

  describe '#global_settings' do
    it 'returns a GlobalSettings instance' do
      db = create_database
      expect(db.global_settings).to be_a(Tinyagent::GlobalSettings)
    end

    it 'memoizes the global_settings' do
      db = create_database
      expect(db.global_settings).to equal(db.global_settings)
    end
  end

  describe '#store' do
    it 'stores a value at the given path' do
      db = create_database
      db.store('hello', at: [:greeting, :message])
      expect(db.fetch(:greeting, :message)).to eq('hello')
    end
  end

  describe '#fetch' do
    it 'returns nil for non-existent keys' do
      db = create_database
      expect(db.fetch(:nonexistent)).to be_nil
    end

    it 'fetches stored values' do
      db = create_database
      db.store('value', at: [:key1, :key2])
      expect(db.fetch(:key1, :key2)).to eq('value')
    end
  end

  describe '#delete' do
    it 'removes stored values' do
      db = create_database
      db.store('value', at: [:key1, :key2])
      db.delete(:key1, :key2)
      expect(db.fetch(:key1, :key2)).to be_nil
    end
  end
end

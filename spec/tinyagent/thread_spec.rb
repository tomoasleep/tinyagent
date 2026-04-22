# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tinyagent::Thread do
  let(:thread) { described_class.create }
  let(:session) { Tinyagent::Session.create(thread_id: thread.id) }

  before do
    thread.update(session_id: session.id)
  end

  describe '#add_message' do
    it 'adds a message to the thread' do
      msg = thread.add_message(role: :user, content: 'Hello')

      expect(msg).to be_a(Tinyagent::Message)
      expect(msg.role).to eq(:user)
      expect(msg.content).to eq('Hello')
      expect(thread.messages.count).to eq(1)
    end

    it 'adds multiple messages in order' do
      thread.add_message(role: :user, content: 'First')
      thread.add_message(role: :assistant, content: 'Second')

      msgs = thread.messages
      expect(msgs.count).to eq(2)
      expect(msgs.first.role).to eq(:user)
      expect(msgs.last.role).to eq(:assistant)
    end
  end

  describe '#messages' do
    it 'returns messages ordered by id' do
      thread.add_message(role: :user, content: 'First')
      thread.add_message(role: :assistant, content: 'Second')

      msgs = thread.messages
      expect(msgs.map(&:content)).to eq(%w[First Second])
    end
  end

  describe '#clear' do
    it 'removes all messages from the thread' do
      thread.add_message(role: :user, content: 'Hello')
      thread.add_message(role: :assistant, content: 'Hi')

      thread.clear

      thread.reload
      expect(thread.messages).to be_empty
    end
  end

  describe '#token_usage' do
    it 'returns token usage from the latest message with token data' do
      thread.add_message(
        role: :user,
        content: 'Hi',
        token_usage_prompt_tokens: 5,
        token_usage_completion_tokens: 3,
        token_usage_total_tokens: 8,
        token_usage_token_limit: 4096
      )
      thread.add_message(
        role: :assistant,
        content: 'Hello',
        token_usage_prompt_tokens: 10,
        token_usage_completion_tokens: 5,
        token_usage_total_tokens: 15,
        token_usage_token_limit: 4096
      )

      tu = thread.token_usage
      expect(tu.total_tokens).to eq(15)
    end

    it 'returns nil when no messages have token data' do
      thread.add_message(role: :user, content: 'Hello')

      expect(thread.token_usage).to be_nil
    end
  end

  describe '#over_auto_compact_threshold?' do
    it 'returns false when no token usage' do
      thread.add_message(role: :user, content: 'Hello')

      expect(thread.over_auto_compact_threshold?).to be false
    end

    it 'returns true when token usage exceeds threshold' do
      thread.add_message(
        role: :assistant,
        content: 'Response',
        token_usage_prompt_tokens: 3500,
        token_usage_completion_tokens: 500,
        token_usage_total_tokens: 4000,
        token_usage_token_limit: 4096
      )

      expect(thread.over_auto_compact_threshold?).to be true
    end
  end
end

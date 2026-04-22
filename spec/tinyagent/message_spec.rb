# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tinyagent::Message do
  let(:thread) { Tinyagent::Thread.create }
  let(:session) { Tinyagent::Session.create(thread_id: thread.id) }

  before do
    thread.update(session_id: session.id)
  end

  def create_message(role:, content:, **opts)
    Tinyagent::Message.create(
      thread_id: thread.id,
      role_id: Tinyagent::Message::ROLES[role],
      content: content,
      **opts
    )
  end

  describe '.create' do
    it 'creates a message with role and content' do
      msg = create_message(role: :user, content: 'Hello')

      expect(msg).to be_exists
      expect(msg.role).to eq(:user)
      expect(msg.content).to eq('Hello')
    end

    it 'creates a system message' do
      msg = create_message(role: :system, content: 'You are helpful')

      expect(msg.role).to eq(:system)
    end

    it 'creates an assistant message' do
      msg = create_message(role: :assistant, content: 'Hi there')

      expect(msg.role).to eq(:assistant)
    end

    it 'creates a tool message' do
      msg = create_message(role: :tool, content: 'result')

      expect(msg.role).to eq(:tool)
    end
  end

  describe '#tool_call?' do
    it 'returns false when no tool calls' do
      msg = create_message(role: :assistant, content: 'Hello')

      expect(msg.tool_call?).to be false
    end

    it 'returns true when tool calls exist' do
      msg = create_message(role: :assistant, content: '')
      Tinyagent::ToolCall.create(
        message_id: msg.id,
        api_id: 'call_123',
        name: 'calculator',
        arguments: '{"expression": "2+2"}'
      )
      msg.reload

      expect(msg.tool_call?).to be true
    end
  end

  describe '#tool_call_id / #tool_name / #tool_arguments' do
    it 'returns tool call details from associated tool call' do
      msg = create_message(role: :assistant, content: '')
      Tinyagent::ToolCall.create(
        message_id: msg.id,
        api_id: 'call_abc',
        name: 'fetch',
        arguments: '{"url": "https://example.com"}'
      )
      msg.reload

      expect(msg.tool_call_id).to eq('call_abc')
      expect(msg.tool_name).to eq('fetch')
      expect(msg.tool_arguments).to eq({ 'url' => 'https://example.com' })
    end

    it 'returns nil when no tool calls' do
      msg = create_message(role: :user, content: 'Hi')

      expect(msg.tool_call_id).to be_nil
      expect(msg.tool_name).to be_nil
      expect(msg.tool_arguments).to be_nil
    end
  end

  describe '#token_usage' do
    it 'returns TokenUsage object when token data is present' do
      msg = create_message(
        role: :assistant,
        content: 'Hi',
        token_usage_prompt_tokens: 10,
        token_usage_completion_tokens: 5,
        token_usage_total_tokens: 15,
        token_usage_token_limit: 4096
      )

      tu = msg.token_usage
      expect(tu).to be_a(Tinyagent::TokenUsage)
      expect(tu.prompt_tokens).to eq(10)
      expect(tu.completion_tokens).to eq(5)
      expect(tu.total_tokens).to eq(15)
    end

    it 'returns nil when no token data' do
      msg = create_message(role: :user, content: 'Hi')

      expect(msg.token_usage).to be_nil
    end
  end

  describe '.from_llm_response' do
    it 'creates a tool response message with associated tool call' do
      tool = Tinyagent::Tool.new(
        name: 'calculator',
        title: 'Calculator',
        description: 'Calculates things',
        input_schema: nil
      )

      msg = described_class.from_llm_response(
        tool: tool,
        tool_call_id: 'call_xyz',
        tool_arguments: { 'expression' => '1+1' },
        tool_response: '2'
      )

      expect(msg.role).to eq(:tool)
      expect(msg.content).to eq('2')
      expect(msg.tool_calls.length).to eq(1)
      expect(msg.tool_calls.first.api_id).to eq('call_xyz')
      expect(msg.tool_calls.first.name).to eq('calculator')
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      msg = create_message(role: :user, content: 'Hello')

      h = msg.to_h
      expect(h[:role]).to eq(:user)
      expect(h[:content]).to eq('Hello')
    end

    it 'returns nil for optional fields' do
      msg = create_message(role: :user, content: 'Hello')

      h = msg.to_h
      expect(h[:tool_call_id]).to be_nil
      expect(h[:tool_name]).to be_nil
      expect(h[:tool_arguments]).to be_nil
      expect(h[:token_usage]).to be_nil
    end
  end
end

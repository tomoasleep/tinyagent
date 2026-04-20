# frozen_string_literal: true

RSpec.describe Tinyagent::ChatMessage do
  describe '#initialize' do
    it 'creates a message with role and content' do
      msg = described_class.new(role: :user, content: 'Hello')
      expect(msg.role).to eq(:user)
      expect(msg.content).to eq('Hello')
    end

    it 'converts string role to symbol' do
      msg = described_class.new(role: 'assistant', content: 'Hi')
      expect(msg.role).to eq(:assistant)
    end

    it 'accepts optional tool fields' do
      msg = described_class.new(
        role: :assistant,
        content: nil,
        tool_call_id: 'call_123',
        tool_name: 'calculator',
        tool_arguments: { 'expression' => '2+2' }
      )
      expect(msg.tool_call_id).to eq('call_123')
      expect(msg.tool_name).to eq('calculator')
      expect(msg.tool_arguments).to eq({ 'expression' => '2+2' })
    end

    it 'accepts token_usage' do
      usage = Tinyagent::TokenUsage.new(
        prompt_tokens: 10,
        completion_tokens: 5,
        total_tokens: 15
      )
      msg = described_class.new(role: :assistant, content: 'Hi', token_usage: usage)
      expect(msg.token_usage).to eq(usage)
    end

    it 'defaults optional fields to nil' do
      msg = described_class.new(role: :user, content: 'Hello')
      expect(msg.tool_call_id).to be_nil
      expect(msg.tool_name).to be_nil
      expect(msg.tool_arguments).to be_nil
      expect(msg.token_usage).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      msg = described_class.new(role: :user, content: 'Hello')
      h = msg.to_h
      expect(h[:role]).to eq(:user)
      expect(h[:content]).to eq('Hello')
      expect(h[:tool_call_id]).to be_nil
      expect(h[:tool_name]).to be_nil
      expect(h[:tool_arguments]).to be_nil
      expect(h[:token_usage]).to be_nil
    end
  end

  describe '#tool_call?' do
    it 'returns true when tool_call_id is present' do
      msg = described_class.new(role: :assistant, content: nil, tool_call_id: 'call_123')
      expect(msg.tool_call?).to be true
    end

    it 'returns false when tool_call_id is nil' do
      msg = described_class.new(role: :assistant, content: 'Hi')
      expect(msg.tool_call?).to be false
    end

    it 'returns false when tool_call_id is empty' do
      msg = described_class.new(role: :assistant, content: 'Hi', tool_call_id: '')
      expect(msg.tool_call?).to be false
    end
  end

  describe '.from_llm_response' do
    it 'creates a tool response message' do
      tool = Tinyagent::Tool.new(
        name: 'calculator',
        title: 'Calculator',
        description: 'Calculates',
        input_schema: {}
      )
      msg = described_class.from_llm_response(
        tool: tool,
        tool_call_id: 'call_123',
        tool_arguments: { 'expression' => '2+2' },
        tool_response: '4'
      )
      expect(msg.role).to eq(:tool)
      expect(msg.content).to eq('4')
      expect(msg.tool_name).to eq('calculator')
      expect(msg.tool_call_id).to eq('call_123')
    end
  end

  describe 'Recordable' do
    it 'includes record_type in to_h' do
      msg = described_class.new(role: :user, content: 'Hello')
      expect(msg.to_h[:record_type]).to eq(:chat_message)
    end
  end
end

# frozen_string_literal: true

RSpec.describe Tinyagent::Agent do
  include OpenAIMockHelper
  include EnvMockHelper

  before { stub_env(OPENAI_API_KEY: 'test-key') }

  let(:llm) { Tinyagent::LLM::OpenAI.new }
  let(:tool) do
    Tinyagent::Tool.new(
      name: 'calculator',
      title: 'Calculator',
      description: 'Performs calculations',
      input_schema: { 'type' => 'object', 'properties' => {}, 'required' => [] }
    ) { |params| "result: #{params['expression']}" }
  end

  describe '#initialize' do
    it 'sets llm, messages, and tools' do
      agent = described_class.new(llm: llm, messages: [], tools: [tool])
      expect(agent.llm).to eq(llm)
      expect(agent.messages).to eq([])
      expect(agent.tools).to eq([tool])
    end

    it 'defaults messages and tools to empty arrays' do
      agent = described_class.new(llm: llm)
      expect(agent.messages).to eq([])
      expect(agent.tools).to eq([])
    end
  end

  describe '#complete' do
    let(:messages) do
      [
        Tinyagent::Message.new(
          role_id: Tinyagent::Message::ROLES[:user],
          content: 'Hello'
        )
      ]
    end

    context 'when response has content' do
      before do
        stub_openai_chat_completion_with_content(
          messages: messages,
          response_content: 'Hi there!'
        )
      end

      it 'returns a response' do
        agent = described_class.new(llm: llm, messages: messages)
        response = agent.complete
        expect(response).to be_a(Tinyagent::LLM::Response)
        expect(response.message.content).to eq('Hi there!')
      end

      it 'adds messages to the agent' do
        agent = described_class.new(llm: llm, messages: messages)
        agent.complete
        expect(agent.messages.length).to eq(2)
      end
    end

    context 'when response has a tool call' do
      before do
        stub_openai_chat_completion_with_tool_call(
          messages: messages,
          tool_name: 'calculator',
          tool_arguments: { 'expression' => '2+2' }
        )

        stub_openai_chat_completion_with_content(
          messages: match([
                            anything,
                            anything,
                            anything
                          ]),
          response_content: 'The result is 4.'
        )
      end

      it 'executes the tool and continues the loop' do
        agent = described_class.new(llm: llm, messages: messages, tools: [tool])
        response = agent.complete
        expect(response.message.content).to eq('The result is 4.')
      end
    end

    context 'with callback' do
      before do
        stub_openai_chat_completion_with_content(
          messages: messages,
          response_content: 'Response'
        )
      end

      it 'yields events to the callback' do
        agent = described_class.new(llm: llm, messages: messages)
        events = []
        agent.complete { |event| events << event[:type] }
        expect(events).to include(:response, :new_message)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tinyagent::Tui::Chat::ChatViewport do
  let(:viewport) { described_class.new }
  let(:message) { instance_double(Tinyagent::Message, role: :user, content: 'Hello', tool_name: nil) }

  describe '#init' do
    it 'returns model and no command', :aggregate_failures do
      model, cmd = viewport.init
      expect(model).to be_a(described_class)
      expect(cmd).to be_nil
    end
  end

  describe '#update' do
    it 'updates messages on RefreshMessagesMessage', :aggregate_failures do
      msg = described_class::RefreshMessagesMessage.new([message])
      updated, cmd = viewport.update(msg)
      expect(updated.view).to include('You: Hello')
      expect(cmd).to be_nil
    end
  end

  describe '#view' do
    context 'with empty messages' do
      it 'returns help text', :aggregate_failures do
        expect(viewport.view).to include('Welcome to tinyagent chat!')
        expect(viewport.view).to include('Press i to enter input mode')
        expect(viewport.view).to include('Press Ctrl+P to open command palette')
      end
    end

    context 'with messages' do
      it 'formats user messages' do
        viewport.update(described_class::RefreshMessagesMessage.new([message]))
        expect(viewport.view).to include('You: Hello')
      end

      it 'formats assistant messages' do
        messages = [instance_double(Tinyagent::Message, role: :assistant, content: 'Hi there', tool_name: nil)]
        viewport.update(described_class::RefreshMessagesMessage.new(messages))
        expect(viewport.view).to include('Assistant: Hi there')
      end
    end

    context 'with tool messages' do
      it 'formats tool messages with name', :aggregate_failures do
        messages = [instance_double(Tinyagent::Message, role: :tool, content: 'tool result', tool_name: 'my_tool')]
        viewport.update(described_class::RefreshMessagesMessage.new(messages))
        expect(viewport.view).to include('⚙ my_tool')
        expect(viewport.view).to include('tool result')
      end

      it 'truncates long tool content' do
        long_content = 'a' * 300
        messages = [instance_double(Tinyagent::Message, role: :tool, content: long_content, tool_name: 'tool')]
        viewport.update(described_class::RefreshMessagesMessage.new(messages))
        expect(viewport.view.length).to be < long_content.length + 50
      end

      it 'uses default tool name when missing' do
        messages = [instance_double(Tinyagent::Message, role: :tool, content: 'result', tool_name: nil)]
        viewport.update(described_class::RefreshMessagesMessage.new(messages))
        expect(viewport.view).to include('⚙ tool')
      end
    end

    context 'with unknown role' do
      it 'returns raw content' do
        messages = [instance_double(Tinyagent::Message, role: :system, content: 'system prompt', tool_name: nil)]
        viewport.update(described_class::RefreshMessagesMessage.new(messages))
        expect(viewport.view).to eq('system prompt')
      end
    end

    it 'joins multiple messages with newlines' do
      messages = [
        instance_double(Tinyagent::Message, role: :user, content: 'A', tool_name: nil),
        instance_double(Tinyagent::Message, role: :assistant, content: 'B', tool_name: nil)
      ]
      viewport.update(described_class::RefreshMessagesMessage.new(messages))
      expect(viewport.view).to eq("You: A\nAssistant: B")
    end
  end
end

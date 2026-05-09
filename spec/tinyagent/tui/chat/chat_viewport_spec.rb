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
      expect(updated.view).to include('Hello')
      expect(cmd).to be_nil
    end
  end

  describe '#view' do
    context 'with empty messages' do
      it 'returns help text', :aggregate_failures do
        expect(viewport.view).to include('Welcome to tinyagent chat!')
        expect(viewport.view).to include('Ctrl+P')
        expect(viewport.view).to include('Ctrl+C')
      end
    end

    context 'with messages' do
      it 'formats user messages with sender style' do
        viewport.update(described_class::RefreshMessagesMessage.new([message]))
        plain = Bubbles::ANSI.strip(viewport.view)
        expect(plain).to include('You: Hello')
      end

      it 'formats assistant messages with sender style' do
        messages = [instance_double(Tinyagent::Message, role: :assistant, content: 'Hi there', tool_name: nil)]
        viewport.update(described_class::RefreshMessagesMessage.new(messages))
        plain = Bubbles::ANSI.strip(viewport.view)
        expect(plain).to include('Assistant: Hi there')
      end
    end

    context 'with tool messages' do
      it 'formats tool messages with name', :aggregate_failures do
        messages = [instance_double(Tinyagent::Message, role: :tool, content: 'tool result', tool_name: 'my_tool')]
        viewport.update(described_class::RefreshMessagesMessage.new(messages))
        plain = Bubbles::ANSI.strip(viewport.view)
        expect(plain).to include('⚙ my_tool')
        expect(plain).to include('tool result')
      end

      it 'truncates long tool content' do
        long_content = 'a' * 300
        messages = [instance_double(Tinyagent::Message, role: :tool, content: long_content, tool_name: 'tool')]
        viewport.update(described_class::RefreshMessagesMessage.new(messages))
        plain = Bubbles::ANSI.strip(viewport.view)
        expect(plain.length).to be < long_content.length + 50
      end

      it 'uses default tool name when missing' do
        messages = [instance_double(Tinyagent::Message, role: :tool, content: 'result', tool_name: nil)]
        viewport.update(described_class::RefreshMessagesMessage.new(messages))
        plain = Bubbles::ANSI.strip(viewport.view)
        expect(plain).to include('⚙ tool')
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
      plain = Bubbles::ANSI.strip(viewport.view)
      expect(plain.lines.map(&:rstrip)).to eq(['You: A', 'Assistant: B'])
    end

    context 'with width for word wrapping' do
      let(:narrow_viewport) { described_class.new(width: 20) }

      it 'wraps long messages to the specified width' do
        msg = instance_double(Tinyagent::Message, role: :user, content: 'This is a long message that should be wrapped', tool_name: nil)
        narrow_viewport.update(described_class::RefreshMessagesMessage.new([msg]))
        view = narrow_viewport.view
        plain = Bubbles::ANSI.strip(view)
        plain.lines.each do |line|
          expect(line.rstrip.length).to be <= 20
        end
      end

      it 'defaults width to 0 when not specified' do
        expect(viewport.instance_variable_get(:@width)).to eq(0)
      end
    end

    context 'with sender color styling' do
      it 'uses USER_STYLE for You: prefix' do
        viewport.update(described_class::RefreshMessagesMessage.new([message]))
        plain = Bubbles::ANSI.strip(viewport.view)
        expect(plain).to start_with('You: Hello')
      end

      it 'uses ASSISTANT_STYLE for Assistant: prefix' do
        messages = [instance_double(Tinyagent::Message, role: :assistant, content: 'Hi', tool_name: nil)]
        viewport.update(described_class::RefreshMessagesMessage.new(messages))
        plain = Bubbles::ANSI.strip(viewport.view)
        expect(plain).to start_with('Assistant: Hi')
      end

      it 'uses TOOL_STYLE for tool messages' do
        messages = [instance_double(Tinyagent::Message, role: :tool, content: 'result', tool_name: 'my_tool')]
        viewport.update(described_class::RefreshMessagesMessage.new(messages))
        plain = Bubbles::ANSI.strip(viewport.view)
        expect(plain).to start_with('⚙ my_tool')
      end
    end
  end
end

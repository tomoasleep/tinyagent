# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tinyagent::Tui::Chat::StatusBar do
  let(:bar) { described_class.new }

  describe '#init' do
    it 'returns model and no command', :aggregate_failures do
      model, cmd = bar.init
      expect(model).to be_a(described_class)
      expect(cmd).to be_nil
    end
  end

  describe '#update' do
    it 'updates status on UpdateStatusMessage', :aggregate_failures do
      msg = described_class::UpdateStatusMessage.new('Cleared.')
      updated, cmd = bar.update(msg)
      expect(updated.view).to include('Cleared.')
      expect(cmd).to be_nil
    end

    it 'updates model info on UpdateModelInfoMessage', :aggregate_failures do
      msg = described_class::UpdateModelInfoMessage.new('openai', 'gpt-4')
      updated, cmd = bar.update(msg)
      expect(updated.view).to include('openai/gpt-4')
      expect(cmd).to be_nil
    end

    it 'updates token usage on UpdateTokenUsageMessage', :aggregate_failures do
      usage = Tinyagent::TokenUsage.new(prompt_tokens: 10, completion_tokens: 5, total_tokens: 15)
      msg = described_class::UpdateTokenUsageMessage.new(usage)
      updated, cmd = bar.update(msg)
      expect(updated.view).to include('tokens:15')
      expect(cmd).to be_nil
    end
  end

  describe '#view' do
    context 'with empty status' do
      it 'returns a string' do
        result = bar.view
        expect(result).to be_a(String)
      end

      it 'includes provider/model info' do
        bar.update(described_class::UpdateModelInfoMessage.new('openai', 'gpt-4'))
        expect(bar.view).to include('openai/gpt-4')
      end
    end

    context 'with status message' do
      it 'includes the status message' do
        bar.update(described_class::UpdateStatusMessage.new('Cleared.'))
        expect(bar.view).to include('Cleared.')
      end
    end

    context 'with token usage' do
      let(:usage) { Tinyagent::TokenUsage.new(prompt_tokens: 30, completion_tokens: 12, total_tokens: 42) }

      it 'includes token count' do
        bar.update(described_class::UpdateTokenUsageMessage.new(usage))
        expect(bar.view).to include('tokens:42')
      end
    end

    context 'with multiple parts' do
      it 'joins parts with pipe' do
        bar.update(described_class::UpdateStatusMessage.new('Done.'))
        bar.update(described_class::UpdateTokenUsageMessage.new(
                     Tinyagent::TokenUsage.new(prompt_tokens: 60, completion_tokens: 40, total_tokens: 100)
                   ))
        bar.update(described_class::UpdateModelInfoMessage.new('anthropic', 'claude-3'))
        expect(bar.view).to include('Done. | tokens:100 | model:anthropic/claude-3')
      end
    end
  end

  describe '#help_text' do
    it 'returns a string' do
      expect(bar.help_text).to be_a(String)
    end

    it 'includes welcome message' do
      expect(bar.help_text).to include('Welcome to tinyagent chat!')
    end

    it 'includes key bindings' do
      expect(bar.help_text).to include('Press i to enter input mode')
    end

    it 'includes slash commands' do
      expect(bar.help_text).to include('/clear')
    end
  end
end

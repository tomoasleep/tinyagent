# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/components/spinner'

RSpec.describe Tinyagent::Tui::Spinner do
  describe '#initialize' do
    it 'creates a spinner with default frames' do
      spinner = described_class.new
      expect(spinner).to be_a(described_class)
    end
  end

  describe '#view' do
    it 'returns a spinner frame string' do
      spinner = described_class.new
      frame = spinner.view
      expect(frame).to match(/\S+/)
    end
  end

  describe 'TickMessage' do
    it 'is a Message subclass' do
      msg = described_class::TickMessage.new
      expect(msg).to be_a(Tinyagent::Tui::Message)
    end
  end

  describe '#update' do
    it 'advances the spinner frame on tick' do
      spinner = described_class.new
      spinner.view
      updated, _cmd = spinner.update(described_class::TickMessage.new)
      second_frame = updated.view
      expect(second_frame).to be_a(String)
    end

    it 'returns [updated_spinner, tick_command]' do
      spinner = described_class.new
      updated, cmd = spinner.update(described_class::TickMessage.new)
      expect([updated.class, cmd.class]).to eq([described_class, Tinyagent::Tui::Commands::BatchCommand])
    end
  end

  describe '#tick' do
    it 'returns a tick command' do
      spinner = described_class.new
      cmd = spinner.tick
      expect(cmd).to be_a(Tinyagent::Tui::Commands::BatchCommand)
    end
  end
end

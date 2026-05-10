# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/core/commands'

RSpec.describe Tinyagent::Tui::Commands do
  describe '.enter_alt_screen' do
    it 'returns an EnterAltScreenCommand' do
      cmd = described_class.enter_alt_screen
      expect(cmd).to be_a(Tinyagent::Tui::Commands::EnterAltScreenCommand)
    end
  end

  describe '.quit' do
    it 'returns a QuitCommand' do
      cmd = described_class.quit
      expect(cmd).to be_a(Tinyagent::Tui::Commands::QuitCommand)
    end
  end

  describe '.batch' do
    it 'returns a BatchCommand with given commands' do
      cmd1 = described_class.enter_alt_screen
      cmd2 = described_class.quit
      batch = described_class.batch([cmd1, cmd2])
      expect([batch.class, batch.commands]).to eq([Tinyagent::Tui::Commands::BatchCommand, [cmd1, cmd2]])
    end
  end

  describe Tinyagent::Tui::Commands::EnterAltScreenCommand do
    it 'has ansi_sequence for alternate screen' do
      cmd = described_class.new
      expect(cmd.ansi_sequence).to include("\e[?1049h")
    end
  end

  describe Tinyagent::Tui::Commands::QuitCommand do
    it 'is a quit signal' do
      cmd = described_class.new
      expect(cmd).to be_a(described_class)
    end
  end

  describe Tinyagent::Tui::Commands::BatchCommand do
    it 'holds multiple commands' do
      cmd1 = Tinyagent::Tui::Commands.enter_alt_screen
      cmd2 = Tinyagent::Tui::Commands.quit
      batch = described_class.new([cmd1, cmd2])
      expect(batch.commands).to eq([cmd1, cmd2])
    end
  end
end

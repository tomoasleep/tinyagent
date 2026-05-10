# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/components/ansi'

RSpec.describe Tinyagent::Tui::Ansi do
  describe '.strip' do
    it 'removes ANSI escape sequences from a string' do
      styled = "\e[38;5;241mHello\e[0m"
      expect(described_class.strip(styled)).to eq('Hello')
    end

    it 'handles strings without ANSI codes' do
      expect(described_class.strip('Hello')).to eq('Hello')
    end

    it 'removes multiple ANSI sequences' do
      styled = "\e[38;5;241mHello\e[0m \e[38;5;205mWorld\e[0m"
      expect(described_class.strip(styled)).to eq('Hello World')
    end

    it 'handles empty strings' do
      expect(described_class.strip('')).to eq('')
    end

    it 'removes reset sequences' do
      styled = "\e[0m"
      expect(described_class.strip(styled)).to eq('')
    end

    it 'removes border characters' do
      styled = "\e[38;5;241m╭─╮\e[0m"
      expect(described_class.strip(styled)).to eq('╭─╮')
    end
  end

  describe '.display_width' do
    it 'computes display width for ASCII strings' do
      expect(described_class.display_width('Hello')).to eq(5)
    end

    it 'computes display width for strings with ANSI codes' do
      styled = "\e[38;5;241mHello\e[0m"
      expect(described_class.display_width(styled)).to eq(5)
    end

    it 'handles CJK full-width characters' do
      expect(described_class.display_width('こんにちは')).to eq(10)
    end

    it 'handles empty strings' do
      expect(described_class.display_width('')).to eq(0)
    end
  end

  describe '.display_height' do
    it 'returns 1 for single-line strings' do
      expect(described_class.display_height('Hello')).to eq(1)
    end

    it 'counts newlines for multi-line strings' do
      expect(described_class.display_height("Hello\nWorld")).to eq(2)
    end

    it 'handles strings with ANSI codes' do
      styled = "\e[38;5;241mHello\nWorld\e[0m"
      expect(described_class.display_height(styled)).to eq(2)
    end

    it 'handles trailing newlines correctly' do
      expect(described_class.display_height("Hello\n")).to eq(1)
    end
  end
end

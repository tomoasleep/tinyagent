# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/components/style'

RSpec.describe Tinyagent::Tui::Style do
  describe '#foreground' do
    it 'sets foreground color' do
      style = described_class.new.foreground('5')
      result = style.render('Hello')
      expect(result).to include('Hello')
    end

    it 'accepts ANSI 256 color codes' do
      style = described_class.new.foreground('209')
      result = style.render('Test')
      expect(Tinyagent::Tui::Ansi.strip(result)).to eq('Test')
    end
  end

  describe '#width' do
    it 'sets rendering width for word wrapping' do
      style = described_class.new.width(20)
      result = style.render('This is a long message that should be wrapped')
      lines = result.split("\n")
      lines.each do |line|
        expect(Tinyagent::Tui::Ansi.display_width(line)).to be <= 22
      end
    end
  end

  describe '#render' do
    it 'renders styled text' do
      style = described_class.new.foreground('241')
      result = style.render('Status')
      expect(Tinyagent::Tui::Ansi.strip(result)).to eq('Status')
    end

    it 'renders plain text when no style applied' do
      style = described_class.new
      result = style.render('Plain')
      expect(result).to eq('Plain')
    end
  end

  describe 'border rendering' do
    it 'renders a bordered box' do
      style = described_class.new
                             .border(:rounded)
                             .padding(0, 1)
                             .width(20)
      result = style.render('Hello')
      plain = Tinyagent::Tui::Ansi.strip(result)
      expect(plain).to match(/╭.*Hello.*╯/m)
    end

    it 'renders with no border when border not set' do
      style = described_class.new.width(20)
      result = style.render('Hello')
      plain = Tinyagent::Tui::Ansi.strip(result)
      expect(plain).not_to include('╭')
    end
  end

  describe 'class methods' do
    describe '.width' do
      it 'computes display width of a string' do
        expect(described_class.width('Hello')).to eq(5)
      end

      it 'computes display width ignoring ANSI codes' do
        styled = "\e[38;5;241mHello\e[0m"
        expect(described_class.width(styled)).to eq(5)
      end

      it 'uses the widest line for multiline strings' do
        text = "Hello\nWelcome to tinyagent"

        expect(described_class.width(text)).to eq('Welcome to tinyagent'.length)
      end
    end

    describe '.height' do
      it 'computes display height of a string' do
        expect(described_class.height("Hello\nWorld")).to eq(2)
      end
    end
  end

  describe 'ROUNDED_BORDER constant' do
    it 'is :rounded symbol' do
      expect(described_class::ROUNDED_BORDER).to eq(:rounded)
    end
  end
end

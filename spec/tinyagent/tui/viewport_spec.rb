# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/components/viewport'

RSpec.describe Tinyagent::Tui::Viewport do
  describe '#initialize' do
    it 'creates a viewport with width and height' do
      vp = described_class.new(width: 80, height: 24)
      expect([vp.width, vp.height]).to eq([80, 24])
    end
  end

  describe '#content=' do
    it 'sets the viewport content' do
      vp = described_class.new(width: 80, height: 24)
      vp.content = "Hello\nWorld"
      expect(vp.view).to include("Hello\nWorld")
    end
  end

  describe '#view' do
    it 'returns the content padded to viewport height' do
      vp = described_class.new(width: 80, height: 24)
      vp.content = 'Short content'
      result = vp.view
      expect([result.start_with?('Short content'), result.split("\n", -1).length]).to eq([true, 24])
    end

    it 'truncates content that exceeds height' do
      lines = (1..30).map { |i| "Line #{i}" }.join("\n")
      vp = described_class.new(width: 80, height: 24)
      vp.content = lines
      result = vp.view
      expect(result.split("\n").length).to be <= 24
    end
  end

  describe '#goto_bottom' do
    it 'scrolls to the bottom of the content' do
      lines = (1..30).map { |i| "Line #{i}" }.join("\n")
      vp = described_class.new(width: 80, height: 10)
      vp.content = lines
      vp.goto_bottom
      result = vp.view
      expect(result).to include('Line 30')
    end
  end

  describe '#at_bottom?' do
    it 'returns true when at the bottom' do
      vp = described_class.new(width: 80, height: 24)
      vp.content = 'Short'
      expect(vp.at_bottom?).to be true
    end

    it 'returns false when not at the bottom' do
      lines = (1..50).map { |i| "Line #{i}" }.join("\n")
      vp = described_class.new(width: 80, height: 10)
      vp.content = lines
      vp.scroll_offset = 0
      expect(vp.at_bottom?).to be false
    end
  end

  describe 'width and height setters' do
    it 'allows updating width' do
      vp = described_class.new(width: 80, height: 24)
      vp.width = 120
      expect(vp.width).to eq(120)
    end

    it 'allows updating height' do
      vp = described_class.new(width: 80, height: 24)
      vp.height = 40
      expect(vp.height).to eq(40)
    end
  end
end

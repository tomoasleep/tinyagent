# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/core/key_message'

RSpec.describe Tinyagent::Tui::KeyMessage do
  describe 'key type constants' do
    it 'defines KEY_ENTER' do
      expect(described_class::KEY_ENTER).to eq('enter')
    end

    it 'defines KEY_ESC' do
      expect(described_class::KEY_ESC).to eq('esc')
    end

    it 'defines KEY_UP' do
      expect(described_class::KEY_UP).to eq('up')
    end

    it 'defines KEY_DOWN' do
      expect(described_class::KEY_DOWN).to eq('down')
    end

    it 'defines KEY_TAB' do
      expect(described_class::KEY_TAB).to eq('tab')
    end

    it 'defines KEY_BACKSPACE' do
      expect(described_class::KEY_BACKSPACE).to eq('backspace')
    end

    it 'defines KEY_CTRL_C' do
      expect(described_class::KEY_CTRL_C).to eq('ctrl+c')
    end

    it 'defines KEY_CTRL_P' do
      expect(described_class::KEY_CTRL_P).to eq('ctrl+p')
    end

    it 'defines KEY_NULL' do
      expect(described_class::KEY_NULL).to eq('null')
    end

    it 'defines KEY_RUNES' do
      expect(described_class::KEY_RUNES).to eq('runes')
    end
  end

  describe '.create' do
    it 'creates a key message with key type' do
      msg = described_class.create(key_type: 'enter')
      expect([msg.key_type, msg.to_s]).to eq(%w[enter enter])
    end

    it 'creates a key message with runes for character input' do
      msg = described_class.create(key_type: 'runes', runes: 'a'.chars.map(&:ord))
      expect([msg.key_type, msg.to_s]).to eq(%w[runes a])
    end

    it 'creates a key message with alt modifier' do
      msg = described_class.create(key_type: 'enter', alt: true)
      expect(msg.alt).to be true
    end

    it 'defaults alt to false' do
      msg = described_class.create(key_type: 'enter')
      expect(msg.alt).to be false
    end

    it 'defaults name to nil' do
      msg = described_class.create(key_type: 'enter')
      expect(msg.name).to be_nil
    end

    it 'stores name when provided' do
      msg = described_class.create(key_type: 'enter', name: 'return')
      expect(msg.name).to eq('return')
    end
  end

  describe '#to_s' do
    it 'returns key type for non-rune keys' do
      msg = described_class.create(key_type: 'enter')
      expect(msg.to_s).to eq('enter')
    end

    it 'returns the character for rune keys' do
      msg = described_class.create(key_type: 'runes', runes: 'h'.chars.map(&:ord))
      expect(msg.to_s).to eq('h')
    end

    it 'joins multiple runes' do
      msg = described_class.create(key_type: 'runes', runes: 'ab'.chars.map(&:ord))
      expect(msg.to_s).to eq('ab')
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/components/text_input'

RSpec.describe Tinyagent::Tui::TextInput do
  describe '#initialize' do
    it 'creates a text input with default values' do
      input = described_class.new
      expect(input.value).to eq('')
    end
  end

  describe '#focus / #blur' do
    it 'focuses the input' do
      input = described_class.new
      input.focus
      expect(input.focused?).to be true
    end

    it 'blurs the input' do
      input = described_class.new
      input.focus
      input.blur
      expect(input.focused?).to be false
    end
  end

  describe '#value=' do
    it 'sets the input value' do
      input = described_class.new
      input.value = 'hello'
      expect(input.value).to eq('hello')
    end
  end

  describe '#reset' do
    it 'clears the input value' do
      input = described_class.new
      input.value = 'hello'
      input.reset
      expect(input.value).to eq('')
    end
  end

  describe '#placeholder=' do
    it 'sets placeholder text' do
      input = described_class.new
      input.placeholder = 'Type here...'
      expect(input.placeholder).to eq('Type here...')
    end
  end

  describe '#width=' do
    it 'sets the input width' do
      input = described_class.new
      input.width = 30
      expect(input.width).to eq(30)
    end
  end

  describe '#prompt=' do
    it 'sets the prompt character' do
      input = described_class.new
      input.prompt = '> '
      expect(input.prompt).to eq('> ')
    end
  end

  describe '#view' do
    it 'renders empty input with placeholder when not focused' do
      input = described_class.new
      input.placeholder = 'Send a message...'
      expect(input.view).to include('Send a message...')
    end

    it 'renders with prompt when focused' do
      input = described_class.new
      input.focus
      input.value = 'hello'
      view = input.view
      expect(view).to include('hello')
    end
  end

  describe '#update' do
    it 'handles character input' do
      input = described_class.new
      input.focus
      updated, _cmd = input.update(Tinyagent::Tui::KeyMessage.create(key_type: 'runes', runes: [104]))
      expect(updated.value).to eq('h')
    end

    it 'handles enter key without outputting character' do
      input = described_class.new
      input.focus
      input.value = 'test'
      updated, _cmd = input.update(Tinyagent::Tui::KeyMessage.create(key_type: 'enter'))
      expect(updated.value).to eq('test')
    end

    it 'handles backspace' do
      input = described_class.new
      input.focus
      input.value = 'ab'
      updated, _cmd = input.update(Tinyagent::Tui::KeyMessage.create(key_type: 'backspace'))
      expect(updated.value).to eq('a')
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'bubbletea'
require 'bubbles'

module KeyHelper
  def key(name, alt: false)
    key_type = case name
               when 'enter' then Bubbletea::KeyMessage::KEY_ENTER
               when 'esc' then Bubbletea::KeyMessage::KEY_ESC
               when 'up' then Bubbletea::KeyMessage::KEY_UP
               when 'down' then Bubbletea::KeyMessage::KEY_DOWN
               when 'tab' then Bubbletea::KeyMessage::KEY_TAB
               when 'backspace' then Bubbletea::KeyMessage::KEY_BACKSPACE
               when 'ctrl+c' then Bubbletea::KeyMessage::KEY_CTRL_C
               else
                 Bubbletea::KeyMessage::KEY_RUNES
               end
    runes = key_type == Bubbletea::KeyMessage::KEY_RUNES ? name.chars.map(&:ord) : []
    Bubbletea::KeyMessage.new(key_type:, runes:, alt:, name:)
  end

  def resize(width, height)
    Bubbletea::WindowSizeMessage.new(width:, height:)
  end

  def type_text(chat, text)
    text.each_char { |c| chat.update(key(c)) }
  end

  def submit_text(chat, text)
    type_text(chat, text)
    chat.update(key('enter'))
  end
end

RSpec.describe Tinyagent::Tui::Chat do
  include KeyHelper

  let(:thread) { Tinyagent::Thread.create }
  let(:chat) { described_class.new(thread:) }

  describe '#initialize' do
    it 'includes Bubbletea::Model' do
      expect(described_class).to include(Bubbletea::Model)
    end

    it 'initializes with idle state' do
      expect(chat.state).to eq(:idle)
    end

    it 'creates a thread by default' do
      chat = described_class.new
      expect(chat.thread).to be_a(Tinyagent::Thread)
    end
  end

  describe '#init' do
    it 'returns model and alt screen command' do
      _model, cmd = chat.init
      expect(cmd).to be_a(Bubbletea::EnterAltScreenCommand)
    end
  end

  describe '#view' do
    it 'returns a string' do
      chat.init
      expect(chat.view).to be_a(String)
    end

    it 'shows help text in idle state' do
      chat.init
      expect(chat.view).to include('Press')
    end
  end

  describe 'state transitions' do
    before { chat.init }

    describe 'idle state' do
      it 'transitions to input on i key' do
        _model, _cmd = chat.update(key('i'))
        expect(chat.state).to eq(:input)
      end

      it 'quits on q key' do
        _model, cmd = chat.update(key('q'))
        expect(cmd).to be_a(Bubbletea::QuitCommand)
      end

      it 'quits on ctrl+c' do
        _model, cmd = chat.update(key('ctrl+c'))
        expect(cmd).to be_a(Bubbletea::QuitCommand)
      end

      it 'passes keys to viewport for scrolling' do
        _model, _cmd = chat.update(key('up'))
        expect(chat.state).to eq(:idle)
      end
    end

    describe 'input state' do
      before { chat.update(key('i')) }

      it 'quits on ctrl+c' do
        _model, cmd = chat.update(key('ctrl+c'))
        expect(cmd).to be_a(Bubbletea::QuitCommand)
      end

      it 'returns to idle on escape' do
        chat.update(key('esc'))
        expect(chat.state).to eq(:idle)
      end

      it 'returns to idle on empty enter' do
        chat.update(key('enter'))
        expect(chat.state).to eq(:idle)
      end

      it 'transitions to thinking on message submit' do
        submit_text(chat, 'Hi')
        expect(chat.state).to eq(:thinking)
      end

      it 'adds user message to thread on submit' do
        submit_text(chat, 'Hi')
        expect(thread.messages.last.role).to eq(:user)
        expect(thread.messages.last.content).to eq('Hi')
      end
    end

    describe 'window resize' do
      it 'updates viewport dimensions' do
        chat.update(resize(120, 40))
        expect(chat.viewport.width).to eq(120)
        expect(chat.viewport.height).to eq(37)
      end
    end
  end

  describe 'message display' do
    before { chat.init }

    it 'shows messages in the viewport' do
      thread.add_message(role: :user, content: 'Hello')
      chat.send(:refresh_viewport)
      expect(chat.view).to include('Hello')
    end

    it 'shows assistant messages' do
      thread.add_message(role: :user, content: 'Q')
      thread.add_message(role: :assistant, content: 'A')
      chat.send(:refresh_viewport)
      expect(chat.view).to include('A')
    end
  end

  describe 'slash commands' do
    before { chat.init }

    it 'clears thread on /clear' do
      thread.add_message(role: :user, content: 'Hello')
      chat.update(key('i'))
      submit_text(chat, '/clear')
      expect(thread.messages_dataset.all).to be_empty
      expect(chat.state).to eq(:idle)
    end

    it 'shows usage on /usage' do
      thread.add_message(
        role: :assistant,
        content: 'Hi',
        token_usage_prompt_tokens: 10,
        token_usage_completion_tokens: 5,
        token_usage_total_tokens: 15,
        token_usage_token_limit: 4096
      )
      chat.update(key('i'))
      submit_text(chat, '/usage')
      expect(chat.view).to include('15')
      expect(chat.state).to eq(:idle)
    end

    it 'ignores unknown slash commands' do
      chat.update(key('i'))
      submit_text(chat, '/xyz')
      expect(chat.state).to eq(:idle)
    end
  end

  describe 'completion' do
    before { chat.init }

    it 'quits on ctrl+c while thinking' do
      chat.update(key('i'))
      submit_text(chat, 'Hi')
      expect(chat.state).to eq(:thinking)

      _model, cmd = chat.update(key('ctrl+c'))
      expect(cmd).to be_a(Bubbletea::QuitCommand)
    end

    it 'returns to idle on CompletionDoneMessage' do
      chat.update(key('i'))
      submit_text(chat, 'Hi')
      expect(chat.state).to eq(:thinking)

      chat.update(Tinyagent::Tui::Chat::CompletionDoneMessage.new)
      expect(chat.state).to eq(:idle)
    end

    it 'returns to idle on CompletionErrorMessage' do
      chat.update(key('i'))
      submit_text(chat, 'Hi')
      expect(chat.state).to eq(:thinking)

      err = StandardError.new('test')
      chat.update(Tinyagent::Tui::Chat::CompletionErrorMessage.new(err))
      expect(chat.state).to eq(:idle)
    end
  end
end

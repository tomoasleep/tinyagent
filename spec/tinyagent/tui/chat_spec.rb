# frozen_string_literal: true

require 'spec_helper'
require 'bubbletea'
require 'bubbles'
require_relative '../../support/key_helper'

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
      expect(chat.view).to include('Ctrl+P')
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

      it 'adds user message to thread on submit', :aggregate_failures do
        submit_text(chat, 'Hi')
        expect(thread.messages.last.role).to eq(:user)
        expect(thread.messages.last.content).to eq('Hi')
      end
    end

    describe 'window resize' do
      it 'updates viewport dimensions', :aggregate_failures do
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

    it 'clears thread on /clear', :aggregate_failures do
      thread.add_message(role: :user, content: 'Hello')
      chat.update(key('i'))
      submit_text(chat, '/clear')
      expect(thread.messages_dataset.all).to be_empty
      expect(chat.state).to eq(:idle)
    end

    it 'shows usage on /usage', :aggregate_failures do
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

  describe 'command palette' do
    before { chat.init }

    it 'opens palette on ctrl+p' do
      chat.update(key('ctrl+p'))
      expect(chat.state).to eq(:palette)
    end

    it 'closes palette on esc' do
      chat.update(key('ctrl+p'))
      chat.update(key('esc'))
      expect(chat.state).to eq(:idle)
    end

    it 'toggles palette on ctrl+p', :aggregate_failures do
      chat.update(key('ctrl+p'))
      expect(chat.state).to eq(:palette)
      chat.update(key('ctrl+p'))
      expect(chat.state).to eq(:idle)
    end

    it 'executes clear command from palette', :aggregate_failures do
      thread.add_message(role: :user, content: 'Hello')
      chat.update(key('ctrl+p'))
      chat.update(key('enter'))
      expect(thread.messages_dataset.all).to be_empty
      expect(chat.state).to eq(:idle)
    end

    it 'executes usage command from palette and shows tokens', :aggregate_failures do
      thread.add_message(
        role: :assistant,
        content: 'Hi',
        token_usage_prompt_tokens: 10,
        token_usage_completion_tokens: 5,
        token_usage_total_tokens: 15,
        token_usage_token_limit: 4096
      )
      chat.update(key('ctrl+p'))
      chat.update(key('enter'))
      expect(chat.state).to eq(:idle)
      expect(chat.view).to include('15')
    end

    it 'navigates and executes compact command from palette', :aggregate_failures do
      chat.update(key('ctrl+p'))
      chat.update(key('down'))
      chat.update(key('enter'))
      expect(chat.state).to eq(:idle)
      expect(chat.view).to include('not yet available')
    end

    it 'quits on ctrl+c while palette is open' do
      chat.update(key('ctrl+p'))
      _model, cmd = chat.update(key('ctrl+c'))
      expect(cmd).to be_a(Bubbletea::QuitCommand)
    end

    it 'renders palette overlay on top of viewport content', :aggregate_failures do
      chat.update(key('ctrl+p'))
      view = chat.view
      plain_lines = view.split("\n").map { |l| Bubbles::ANSI.strip(l).rstrip }

      expect(plain_lines.length).to eq(23)
      expect(plain_lines[0]).to start_with('Welcome to tinyagent')
      overlay_lines = plain_lines.select { |l| l.include?('╭') || l.include?('╰') }
      expect(overlay_lines).not_to be_empty
    end

    it 'shows viewport text alongside palette border', :aggregate_failures do
      chat.update(key('ctrl+p'))
      plain_lines = chat.view.split("\n").map { |l| Bubbles::ANSI.strip(l).rstrip }

      expect(plain_lines[2]).to start_with('Press i to enter inpu')
      expect(plain_lines.any? { |l| l.include?('│') && l.include?('clear') }).to be true
      expect(plain_lines.any? { |l| l.include?('esc to close') }).to be true
    end

    it 'has separator and help bar below overlay', :aggregate_failures do
      chat.update(key('ctrl+p'))
      view = chat.view
      plain_lines = view.split("\n").map { |l| Bubbles::ANSI.strip(l).rstrip }

      expect(plain_lines[21]).to start_with('──')
      expect(plain_lines[22]).to include('navigate')
      expect(plain_lines[22]).to include('esc')
    end

    it 'shows palette-specific help bar instead of status bar', :aggregate_failures do
      chat.update(key('ctrl+p'))
      view = chat.view
      expect(view).to include('navigate')
      expect(view).to include('enter: execute')
      expect(view).not_to include('i:input')
    end

    it 'opens palette from input mode' do
      chat.update(key('i'))
      chat.update(key('ctrl+p'))
      expect(chat.state).to eq(:palette)
    end

    it 'filters commands with fuzzy matching', :aggregate_failures do
      chat.update(key('ctrl+p'))
      type_text(chat, 'cl')
      items = chat.instance_variable_get(:@command_palette).visible_items
      expect(items.length).to eq(1)
      expect(items.first[:title]).to eq('clear')
    end

    it 'resets filter on palette reopen', :aggregate_failures do
      chat.update(key('ctrl+p'))
      type_text(chat, 'cl')
      chat.update(key('esc'))
      chat.update(key('ctrl+p'))
      expect(chat.state).to eq(:palette)
      items = chat.instance_variable_get(:@command_palette).visible_items
      expect(items.length).to eq(3)
    end

    it 'shows all items when filter is empty' do
      chat.update(key('ctrl+p'))
      type_text(chat, 'c')
      chat.update(key('backspace'))
      items = chat.instance_variable_get(:@command_palette).visible_items
      expect(items.length).to eq(3)
    end

    it 'executes filtered command', :aggregate_failures do
      thread.add_message(role: :user, content: 'Hello')
      chat.update(key('ctrl+p'))
      type_text(chat, 'cl')
      chat.update(key('enter'))
      expect(thread.messages_dataset.all).to be_empty
      expect(chat.state).to eq(:idle)
    end
  end

  describe 'completion' do
    before { chat.init }

    it 'quits on ctrl+c while thinking', :aggregate_failures do
      chat.update(key('i'))
      submit_text(chat, 'Hi')
      expect(chat.state).to eq(:thinking)

      _model, cmd = chat.update(key('ctrl+c'))
      expect(cmd).to be_a(Bubbletea::QuitCommand)
    end

    it 'returns to idle on CompletionDoneMessage', :aggregate_failures do
      chat.update(key('i'))
      submit_text(chat, 'Hi')
      expect(chat.state).to eq(:thinking)

      chat.update(Tinyagent::Tui::Chat::CompletionDoneMessage.new)
      expect(chat.state).to eq(:idle)
    end

    it 'returns to idle on CompletionErrorMessage', :aggregate_failures do
      chat.update(key('i'))
      submit_text(chat, 'Hi')
      expect(chat.state).to eq(:thinking)

      err = StandardError.new('test')
      chat.update(Tinyagent::Tui::Chat::CompletionErrorMessage.new(err))
      expect(chat.state).to eq(:idle)
    end
  end
end

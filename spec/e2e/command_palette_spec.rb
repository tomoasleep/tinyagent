# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'command palette', type: :e2e do
  let(:screen_size) { { cols: 80, rows: 14 } }

  it 'opens command palette on Ctrl+P' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('clear', timeout: 5)

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      Welcome to tinyagent chat!
                           ╭────────────────────────────────────╮
      Press i to enter inpu│  Type to filter...                 │
      Press Ctrl+P to open │  > clear                           │
      Press Ctrl+M to chang│    compact                         │
      Press q or Ctrl+C to │    usage                           │
      Use /clear, /compact,│  esc to close                      │
                           ╰────────────────────────────────────╯



      ───────────────────────────────────────────────────────────────────────────────
      ↑↓ navigate | enter: execute | esc: close
    SCREEN
  end

  it 'closes command palette on Esc' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('clear', timeout: 5)
    session.press('esc')

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      Welcome to tinyagent chat!

      Press i to enter input mode
      Press Ctrl+P to open command palette
      Press Ctrl+M to change model
      Press q or Ctrl+C to quit
      Use /clear, /compact, /usage for commands




      ───────────────────────────────────────────────────────────────────────────────
      model:openai/gpt-5-nano
    SCREEN
  end

  it 'executes clear command from palette' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('clear', timeout: 5)
    session.press('enter')

    session.wait_for_text('Cleared.', timeout: 5)

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      Welcome to tinyagent chat!

      Press i to enter input mode
      Press Ctrl+P to open command palette
      Press Ctrl+M to change model
      Press q or Ctrl+C to quit
      Use /clear, /compact, /usage for commands




      ───────────────────────────────────────────────────────────────────────────────
      Cleared. | model:openai/gpt-5-nano
    SCREEN
  end

  it 'navigates and executes compact command' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('clear', timeout: 5)
    session.press('down')
    session.press('enter')

    session.wait_for_text('Compact not yet available.', timeout: 5)

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      Welcome to tinyagent chat!

      Press i to enter input mode
      Press Ctrl+P to open command palette
      Press Ctrl+M to change model
      Press q or Ctrl+C to quit
      Use /clear, /compact, /usage for commands




      ───────────────────────────────────────────────────────────────────────────────
      Compact not yet available. | model:openai/gpt-5-nano
    SCREEN
  end

  it 'filters commands with fuzzy search' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('clear', timeout: 5)
    session.type('cl')

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      Welcome to tinyagent chat!

      Press i to enter input mode
      Press Ctrl+P to open ╭────────────────────────────────────╮
      Press Ctrl+M to chang│  cl                                │
      Press q or Ctrl+C to │  > clear                           │
      Use /clear, /compact,│  esc to close                      │
                           ╰────────────────────────────────────╯



      ───────────────────────────────────────────────────────────────────────────────
      ↑↓ navigate | enter: execute | esc: close
    SCREEN
  end

  it 'toggles palette with Ctrl+P' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('clear', timeout: 5)
    session.press('ctrl', 'p')

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      Welcome to tinyagent chat!

      Press i to enter input mode
      Press Ctrl+P to open command palette
      Press Ctrl+M to change model
      Press q or Ctrl+C to quit
      Use /clear, /compact, /usage for commands




      ───────────────────────────────────────────────────────────────────────────────
      model:openai/gpt-5-nano
    SCREEN
  end
end

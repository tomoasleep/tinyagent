# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'slash commands', type: :e2e do
  let(:screen_size) { { cols: 80, rows: 12 } }

  it 'shows usage info on /usage when no data' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.type('/usage')
    session.press('enter')

    session.wait_for_text('No token usage data.', timeout: 5)

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      Welcome to tinyagent chat!

      Press Ctrl+P to open command palette
      Press Ctrl+C to quit
      Use /clear, /compact, /usage for commands



      ───────────────────────────────────────────────────────────────────────────────
      No token usage data.
      ┃ Send a message...
      model:openai/gpt-5-nano
    SCREEN
  end

  it 'clears messages on /clear' do
    aimock.add_catch_all_fixture(content: 'reply')

    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.type('test message')
    session.press('enter')

    session.wait_for_text('reply', timeout: 10)

    session.type('/clear')
    session.press('enter')

    session.wait_for_text('Cleared.', timeout: 5)
    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      Welcome to tinyagent chat!

      Press Ctrl+P to open command palette
      Press Ctrl+C to quit
      Use /clear, /compact, /usage for commands



      ───────────────────────────────────────────────────────────────────────────────
      Cleared.
      ┃ Send a message...
      model:openai/gpt-5-nano
    SCREEN
  end

  it 'shows compact not available on /compact' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.type('/compact')
    session.press('enter')

    session.wait_for_text('Compact not yet available.', timeout: 5)

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      Welcome to tinyagent chat!

      Press Ctrl+P to open command palette
      Press Ctrl+C to quit
      Use /clear, /compact, /usage for commands



      ───────────────────────────────────────────────────────────────────────────────
      Compact not yet available.
      ┃ Send a message...
      model:openai/gpt-5-nano
    SCREEN
  end
end

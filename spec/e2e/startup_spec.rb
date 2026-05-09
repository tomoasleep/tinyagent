# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'startup', type: :e2e do
  let(:screen_size) { { cols: 80, rows: 12 } }

  it 'shows welcome message on startup' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      Welcome to tinyagent chat!

      Press i to enter input mode
      Press Ctrl+P to open command palette
      Press q or Ctrl+C to quit
      Use /clear, /compact, /usage for commands

      ───────────────────────────────────────────────────────────────────────────────
      model:openai/gpt-5-nano
    SCREEN
  end
end

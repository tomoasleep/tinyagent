# frozen_string_literal: true

require_relative '../e2e_helper'

RSpec.describe 'change model command', type: :e2e do
  let(:screen_size) { { cols: 80, rows: 14 } }

  it 'opens provider selection from change model command' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('change model', timeout: 5)
    session.press('down')
    session.press('down')
    session.press('down')
    session.press('enter')

    session.wait_for_text('choose provider', timeout: 5)

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      Welcome to tinyagent ╭────────────────────────────────────╮
                           │  Type to filter...                 │
      Press i to enter inpu│  > 302.AI                          │
      Press Ctrl+P to open │    Alibaba                         │
      Press q or Ctrl+C to │    Scaleway                        │
      Use /clear, /compact,│    NanoGPT                         │
                           │    Abacus                          │
                           │    SiliconFlow (China)             │
                           │    submodel                        │
                           │  esc to close                      │
                           ╰────────────────────────────────────╯
      ───────────────────────────────────────────────────────────────────────────────
      ↑↓ navigate | enter: choose provider | esc: close
    SCREEN
  end
end

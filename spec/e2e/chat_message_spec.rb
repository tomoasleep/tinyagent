# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'chat message exchange', type: :e2e do
  let(:screen_size) { { cols: 80, rows: 12 } }

  it 'sends a message and receives a response' do
    aimock.add_catch_all_fixture(content: 'Hi there! How can I help?')

    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('i')
    session.type('Hello')
    session.press('enter')

    session.wait_for_text('Hi there! How can I help?', timeout: 15)

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      You: Hello
      Assistant: Hi there! How can I help?







      ───────────────────────────────────────────────────────────────────────────────
      tokens:0 | model:openai/gpt-5-nano
    SCREEN
  end
end

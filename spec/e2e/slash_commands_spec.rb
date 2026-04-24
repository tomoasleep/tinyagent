# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'slash commands', type: :e2e do
  it 'shows usage info on /usage when no data' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('i')
    session.type('/usage')
    session.press('enter')

    text = session.wait_for_text('No token usage data.', timeout: 5)
    expect(text).to include('No token usage data.')
  end

  it 'clears messages on /clear' do
    aimock.on_message('test message', content: 'reply')

    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('i')
    session.type('test message')
    session.press('enter')

    session.wait_for_text('reply', timeout: 10)

    session.press('i')
    session.type('/clear')
    session.press('enter')

    text = session.wait_for_text('Cleared.', timeout: 5)
    expect(text).to include('Cleared.')
  end

  it 'shows compact not available on /compact' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('i')
    session.type('/compact')
    session.press('enter')

    text = session.wait_for_text('Compact not yet available.', timeout: 5)
    expect(text).to include('Compact not yet available.')
  end
end

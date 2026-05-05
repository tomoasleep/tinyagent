# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'chat message exchange', type: :e2e do
  it 'sends a message and receives a response' do
    aimock.add_catch_all_fixture(content: 'Hi there! How can I help?')

    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('i')
    session.type('Hello')
    session.press('enter')

    response = session.wait_for_text('Hi there! How can I help?', timeout: 15)
    expect(response).to include('Hi there! How can I help?')

    after_response = session.snapshot(trim: true)
    expect(after_response).to include('You: Hello')
    expect(after_response).to include('Assistant: Hi there! How can I help?')
  end
end

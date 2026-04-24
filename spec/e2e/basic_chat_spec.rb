# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'basic chat flow', type: :e2e do
  it 'shows welcome message on startup' do
    text = session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)
    expect(text).to include('Press i to enter input mode')
  end

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

  it 'quits on q key' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('q')
  end

  it 'quits on ctrl+c' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl c')
  end
end

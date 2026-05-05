# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'startup', type: :e2e do
  it 'shows welcome message on startup' do
    text = session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)
    expect(text).to include('Press i to enter input mode')
  end
end

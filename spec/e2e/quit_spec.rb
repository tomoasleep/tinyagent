# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'quit', type: :e2e do
  it 'quits on ctrl+c' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    expect { session.press('ctrl c') }.not_to raise_error
  end
end

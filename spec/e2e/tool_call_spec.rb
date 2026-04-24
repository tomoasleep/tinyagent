# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'tool call flow', type: :e2e do
  # rubocop:disable RSpec/PendingWithoutReason
  xit 'executes a tool call and shows the result' do
    # rubocop:enable RSpec/PendingWithoutReason
    aimock.add_fixture(
      {
        match: { userMessage: 'What is 2+2?' },
        response: {
          toolCalls: [
            {
              id: 'call_calc_1',
              name: 'calculator',
              arguments: { expression: '2+2' }
            }
          ]
        }
      }
    )

    aimock.on_tool_result('call_calc_1', content: 'result: 4')

    aimock.on_message(/result: 4/, content: 'The result of 2+2 is 4.')

    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('i')
    session.type('What is 2+2?')
    session.press('enter')

    text = session.wait_for_text('The result of 2+2 is 4.', timeout: 15)
    expect(text).to include('You: What is 2+2?')
    expect(text).to include('Assistant: The result of 2+2 is 4.')
  end
end

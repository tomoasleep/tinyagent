# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'tool call flow', type: :e2e do
  let(:screen_size) { { cols: 80, rows: 12 } }

  it 'executes a tool call and shows the result' do
    pending 'Requires AIMock server running'
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

    session.type('What is 2+2?')
    session.press('enter')

    session.wait_for_text('The result of 2+2 is 4.', timeout: 15)

    expect(session.snapshot(trim: true)).to match_screen('')
  end
end

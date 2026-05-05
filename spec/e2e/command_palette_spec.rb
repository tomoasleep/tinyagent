# frozen_string_literal: true

require_relative 'e2e_helper'

RSpec.describe 'command palette', type: :e2e do
  it 'opens command palette on Ctrl+P' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')

    text = session.wait_for_text('clear', timeout: 5)
    expect(text).to include('clear')
    expect(text).to include('compact')
    expect(text).to include('usage')
    expect(text).to include('esc to close')
  end

  it 'closes command palette on Esc' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('clear', timeout: 5)
    session.press('esc')

    text = session.snapshot(trim: true)
    expect(text).not_to include('esc to close')
  end

  it 'renders palette as overlay with rounded border' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    text = session.wait_for_text('clear', timeout: 5)

    expect(text).to include('╭')
    expect(text).to include('╮')
    expect(text).to include('╰')
    expect(text).to include('╯')
  end

  it 'executes clear command from palette' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('clear', timeout: 5)

    session.press('enter')

    text = session.wait_for_text('Cleared.', timeout: 5)
    expect(text).to include('Cleared.')
    expect(text).not_to include('esc to close')
  end

  it 'navigates and executes compact command' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('clear', timeout: 5)
    session.press('down')
    session.press('enter')

    text = session.wait_for_text('Compact not yet available.', timeout: 5)
    expect(text).to include('Compact not yet available.')
  end

  it 'filters commands with fuzzy search' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('clear', timeout: 5)

    session.type('cl')

    text = session.snapshot(trim: true)
    expect(text).to include('cl')
    expect(text).to include('> clear')
    expect(text).not_to include('Type to filter...')
  end

  it 'toggles palette with Ctrl+P' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)

    session.press('ctrl', 'p')
    session.wait_for_text('clear', timeout: 5)

    session.press('ctrl', 'p')

    text = session.snapshot(trim: true)
    expect(text).not_to include('esc to close')
  end
end

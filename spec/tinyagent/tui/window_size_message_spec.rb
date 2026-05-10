# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/core/window_size_message'

RSpec.describe Tinyagent::Tui::WindowSizeMessage do
  it 'stores width and height' do
    msg = described_class.new(width: 120, height: 40)
    expect([msg.width, msg.height]).to eq([120, 40])
  end

  it 'defaults to reasonable values' do
    msg = described_class.new(width: 80, height: 24)
    expect([msg.width, msg.height]).to eq([80, 24])
  end
end

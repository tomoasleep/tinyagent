# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/core/message'

RSpec.describe Tinyagent::Tui::Message do
  it 'is a base class for messages' do
    msg = described_class.new
    expect(msg).to be_a(described_class)
  end

  it 'allows subclassing' do
    subclass = Class.new(described_class)
    instance = subclass.new
    expect(instance).to be_a(described_class)
  end
end

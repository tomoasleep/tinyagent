# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/core/model'
require 'tinyagent/tui/core/message'

RSpec.describe Tinyagent::Tui::Model do
  let(:model_class) do
    Class.new do
      include Tinyagent::Tui::Model

      def initialize
        @count = 0
      end

      def init
        [self, nil]
      end

      def update(_message)
        @count += 1
        [self, nil]
      end

      def view
        "count: #{@count}"
      end
    end
  end

  it 'provides init, update, and view methods' do
    instance = model_class.new
    expect(%i[init update view].all? { |name| instance.respond_to?(name) }).to be true
  end

  it 'returns [self, command] from init' do
    instance = model_class.new
    expect(instance.init).to eq([instance, nil])
  end

  it 'returns [self, command] from update' do
    instance = model_class.new
    msg = Tinyagent::Tui::Message.new
    expect(instance.update(msg)).to eq([instance, nil])
  end
end

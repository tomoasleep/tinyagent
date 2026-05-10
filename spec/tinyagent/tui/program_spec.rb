# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/core/program'

RSpec.describe Tinyagent::Tui::Program do
  let(:model_class) do
    Class.new do
      include Tinyagent::Tui::Model

      def init
        [self, nil]
      end

      def update(_message)
        [self, nil]
      end

      def view
        'hello'
      end
    end
  end

  let(:command_model_class) do
    Class.new do
      include Tinyagent::Tui::Model

      def init
        [self, Tinyagent::Tui::Commands.enter_alt_screen]
      end

      def update(_message)
        [self, nil]
      end

      def view
        'hello'
      end
    end
  end

  describe '.run' do
    it 'accepts a model and calls init' do
      program = described_class.new(model: model_class.new)
      expect(program).to be_a(described_class)
    end
  end

  describe '#start' do
    it 'executes init commands from model' do
      program = described_class.new(model: command_model_class.new)
      allow(program).to receive(:execute_loop)

      program.start

      expect(program).to have_received(:execute_loop)
    end

    it 'wraps the input loop in raw mode when available' do
      program = described_class.new(model: model_class.new)

      allow(program).to receive(:send_window_size)
      allow(program).to receive(:execute_loop)
      allow($stdin).to receive(:tty?).and_return(true)
      allow($stdin).to receive(:raw).and_yield

      program.start

      expect($stdin).to have_received(:raw)
    end

    it 'sends the initial window size before entering the loop' do
      program = described_class.new(model: model_class.new)

      allow(program).to receive(:send_window_size)
      allow(program).to receive(:execute_loop)

      program.start

      expect(program).to have_received(:send_window_size)
    end

    it 'enters the execution loop after startup' do
      program = described_class.new(model: model_class.new)

      allow(program).to receive(:send_window_size)
      allow(program).to receive(:execute_loop)

      program.start

      expect(program).to have_received(:execute_loop)
    end
  end

  describe '#parse_escape_sequence' do
    it 'parses esc as the esc key' do
      program = described_class.new(model: model_class.new)

      message = program.send(:parse_escape_sequence, "\e")

      expect(message.to_s).to eq('esc')
    end

    it 'parses down arrow sequences' do
      program = described_class.new(model: model_class.new)

      message = program.send(:parse_escape_sequence, "\e[B")

      expect(message.to_s).to eq('down')
    end
  end

  describe '#read_escaped_key' do
    it 'collects a split arrow-key escape sequence' do
      program = described_class.new(model: model_class.new)

      allow($stdin).to receive(:wait_readable).and_return(true, true, nil)
      allow($stdin).to receive(:read_nonblock).with(1).and_return('[', 'B')

      message = program.send(:read_escaped_key)

      expect(message.to_s).to eq('down')
    end
  end
end

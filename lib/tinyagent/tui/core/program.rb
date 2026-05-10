# frozen_string_literal: true

require 'io/console'
require 'tty-cursor'
require 'tty-screen'
require_relative 'commands'
require_relative 'message'
require_relative 'model'

module Tinyagent
  module Tui
    # Terminal program loop for the custom TUI runtime.
    class Program
      # @rbs @model: untyped
      # @rbs @alt_screen: bool
      # @rbs @running: bool
      # @rbs @sigwinch_handler: String?
      # @rbs @sigwinch_pending: bool

      # @rbs model: untyped
      # @rbs alt_screen: bool
      def initialize(model:, alt_screen: false) #: void
        @model = model
        @alt_screen = alt_screen
        @running = false
        @sigwinch_handler = nil
        @sigwinch_pending = false
      end

      def start #: void
        @running = true
        model, cmd = @model.init
        @model = model
        execute_command(cmd) if cmd

        if @alt_screen
          $stdout.write(Commands::EnterAltScreenCommand.new.ansi_sequence)
          $stdout.flush
        end

        with_raw_input do
          send_window_size
          execute_loop
        end
      end

      def stop #: void
        @running = false
        return unless @alt_screen

        $stdout.write(Commands::EnterAltScreenCommand::ANSI_ALT_SCREEN_ON.sub('1049h', '1049l'))
        show_cursor
      end

      private

      def execute_loop #: void
        hide_cursor
        render
        setup_sigwinch
        read_and_process_input while @running
      ensure
        restore_sigwinch
        show_cursor
      end

      def hide_cursor #: void
        $stdout.write(TTY::Cursor.hide)
        $stdout.flush
      end

      def show_cursor #: void
        $stdout.write(TTY::Cursor.show)
        $stdout.flush
      end

      def render #: void
        output = @model.view
        $stdout.write(TTY::Cursor.move_to(0, 0) + TTY::Cursor.clear_screen_down + output)
        $stdout.flush
      end

      def read_and_process_input #: void
        check_sigwinch
        key_char = read_key
        return unless key_char

        message = build_message(key_char)
        @model, cmd = @model.update(message) if message
        execute_command(cmd) if cmd
        render
      end

      def read_key #: KeyMessage?
        if stdin.respond_to?(:read_nonblock)
          begin
            char = stdin.read_nonblock(1)
            read_escape_sequence(char)
          rescue IO::WaitReadable
            sleep 0.01
            nil
          rescue EOFError
            @running = false
            nil
          end
        else
          char = stdin.getch
          read_escape_sequence(char)
        end
      end

      # @rbs char: String
      def read_escape_sequence(char) #: KeyMessage?
        case char
        when "\e"
          read_escaped_key
        when "\r", "\n"
          KeyMessage.create(key_type: KeyMessage::KEY_ENTER)
        when "\x03"
          KeyMessage.create(key_type: KeyMessage::KEY_CTRL_C)
        when "\x10"
          KeyMessage.create(key_type: KeyMessage::KEY_CTRL_P)
        when "\x7f", "\x08"
          KeyMessage.create(key_type: KeyMessage::KEY_BACKSPACE)
        when "\t"
          KeyMessage.create(key_type: KeyMessage::KEY_TAB)
        else
          KeyMessage.create(key_type: KeyMessage::KEY_RUNES, runes: char.chars.map(&:ord)) if char.ord >= 32
        end
      end

      def read_escaped_key #: KeyMessage?
        sequence = +"\e"
        while input_ready?(sequence.length == 1 ? 0.01 : 0.0)
          begin
            sequence << stdin.read_nonblock(1)
          rescue IO::WaitReadable, EOFError
            break
          end
        end

        parse_escape_sequence(sequence)
      end

      # @rbs sequence: String
      def parse_escape_sequence(sequence) #: KeyMessage?
        case sequence
        when "\e"
          KeyMessage.create(key_type: KeyMessage::KEY_ESC)
        when "\e[A"
          KeyMessage.create(key_type: KeyMessage::KEY_UP)
        when "\e[B"
          KeyMessage.create(key_type: KeyMessage::KEY_DOWN)
        end
      end

      # @rbs &: () -> void
      def with_raw_input(&) #: void
        return yield unless stdin.respond_to?(:raw) && stdin.tty?

        stdin.raw(&)
      end

      # @rbs timeout: Float
      def input_ready?(timeout) #: bool
        !stdin.wait_readable(timeout).nil?
      end

      def stdin #: untyped
        $stdin
      end

      def kernel #: untyped
        Kernel
      end

      # @rbs key_char: KeyMessage
      def build_message(key_char) #: KeyMessage
        key_char
      end

      # @rbs cmd: untyped
      def execute_command(cmd) #: void
        case cmd
        when Commands::QuitCommand
          stop
        when Commands::BatchCommand
          cmd.commands.each { |c| execute_command(c) }
        when Commands::EnterAltScreenCommand
          nil
        when Proc
          execute_proc_command(cmd)
        end
      end

      # @rbs proc_cmd: Proc
      def execute_proc_command(proc_cmd) #: void
        result = proc_cmd.call
        case result
        when Message
          @model, cmd = @model.update(result)
          execute_command(cmd) if cmd
        when Commands::QuitCommand
          stop
        when Commands::BatchCommand
          execute_command(result)
        end
      end

      def send_window_size #: void
        width = (TTY::Screen.width || 80) - 1
        height = TTY::Screen.height || 24
        msg = WindowSizeMessage.new(width: width, height: height)
        @model, cmd = @model.update(msg)
        execute_command(cmd) if cmd
      end

      def setup_sigwinch #: void
        @sigwinch_handler = kernel.trap('WINCH') do
          @sigwinch_pending = true
        end
      end

      def restore_sigwinch #: void
        kernel.trap('WINCH', @sigwinch_handler) if @sigwinch_handler
      end

      def check_sigwinch #: void
        return unless @sigwinch_pending

        @sigwinch_pending = false
        send_window_size
        render
      end
    end
  end
end

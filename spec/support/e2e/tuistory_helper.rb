# frozen_string_literal: true

require 'open3'
require 'shellwords'
require 'timeout'

module E2E
  module TuistoryHelper
    PROJECT_ROOT = File.expand_path('../../../..', __dir__)
    E2E_DIR = __dir__
    RUN_TUI_SCRIPT = File.join(E2E_DIR, 'run-tui.sh')

    class Session
      attr_reader :name, :aimock_url

      def initialize(name:, aimock_url:)
        @name = name
        @aimock_url = aimock_url
        launch
      end

      def snapshot(trim: false)
        flag = trim ? ' --trim' : ''
        tuistory("-s #{name} snapshot#{flag}")
      end

      def type(text)
        tuistory("-s #{name} type #{Shellwords.escape(text)}")
      end

      def press(key)
        tuistory("-s #{name} press #{key}")
      end

      def wait_for_text(pattern, timeout: 10)
        pattern_str = pattern.is_a?(Regexp) ? pattern.inspect : Shellwords.escape(pattern)
        tuistory("-s #{name} wait #{pattern_str} --timeout #{timeout * 1000}", timeout: timeout + 5)
        snapshot(trim: true)
      end

      def close
        tuistory("-s #{name} close")
      rescue StandardError
        nil
      end

      private

      def launch
        tuistory(
          [
            "launch '#{RUN_TUI_SCRIPT}'",
            "-s #{name}",
            '--cols 120',
            '--rows 36',
            "--cwd #{PROJECT_ROOT}",
            '--env OPENAI_API_KEY=test-key',
            "--env OPENAI_BASE_URL=#{aimock_url}",
            '--env OPENAI_MODEL=gpt-5-nano',
            "--env PATH=#{Shellwords.escape(ENV.fetch('PATH', ''))}",
            "--env HOME=#{Shellwords.escape(ENV.fetch('HOME', '/tmp'))}"
          ].join(' '),
          timeout: 20
        )
      end

      def tuistory(args, timeout: 15)
        cmd = "npx tuistory #{args}"
        stdout, stderr, status = nil
        Timeout.timeout(timeout) do
          stdout, stderr, status = Open3.capture3(cmd)
        end
        raise "tuistory command failed: #{cmd}\nstdout: #{stdout}\nstderr: #{stderr}" unless status&.success?

        stdout&.strip.to_s
      rescue Timeout::Error
        raise "tuistory command timed out after #{timeout}s: #{cmd}"
      end
    end
  end
end

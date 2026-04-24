# frozen_string_literal: true

require 'English'
require 'net/http'
require 'json'
require 'open3'

module E2E
  module AimockHelper
    E2E_DIR = __dir__
    STARTER_SCRIPT = File.join(E2E_DIR, 'start-aimock.cjs')

    class AimockServer
      attr_reader :url

      def initialize
        @pid = nil
        @url = nil
      end

      def start
        install_aimock unless aimock_installed?

        env = {
          'PATH' => ENV.fetch('PATH', ''),
          'HOME' => ENV.fetch('HOME', '/tmp'),
          'NODE_OPTIONS' => '--no-deprecation'
        }

        @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(env, 'node', STARTER_SCRIPT, chdir: E2E_DIR)

        url_line = nil
        30.times do
          sleep 0.5
          url_line ||= read_available_line
          next unless url_line

          @url = url_line.strip
          @pid = @wait_thr.pid

          uri = URI("#{@url}/__aimock/health")
          resp = begin
            Net::HTTP.get_response(uri)
          rescue Errno::ECONNREFUSED
            nil
          end

          next unless resp.is_a?(Net::HTTPSuccess)

          body = JSON.parse(resp.body)
          return self if body['status'] == 'ok'
        end

        raise 'AIMock server failed to start within 15 seconds'
      end

      def stop
        return unless @pid

        Process.kill('TERM', @pid)
        Process.wait(@pid)
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      ensure
        @pid = nil
        @stdin&.close
        @stdout&.close
        @stderr&.close
      end

      def base_url
        @url
      end

      def v1_url
        "#{base_url}/v1"
      end

      def add_fixture(fixture)
        uri = URI("#{base_url}/__aimock/fixtures")
        Net::HTTP.post(uri, JSON.generate({ fixtures: [fixture] }), 'Content-Type' => 'application/json')
      end

      def add_fixtures(fixtures)
        uri = URI("#{base_url}/__aimock/fixtures")
        Net::HTTP.post(uri, JSON.generate({ fixtures: }), 'Content-Type' => 'application/json')
      end

      def clear_fixtures
        uri = URI("#{base_url}/__aimock/fixtures")
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Delete.new(uri.path)
          http.request(request)
        end
      end

      def reset
        uri = URI("#{base_url}/__aimock/reset")
        Net::HTTP.post(uri, '', 'Content-Type' => 'application/json')
      end

      def reset_match_counts
        reset
      end

      def journal
        uri = URI("#{base_url}/__aimock/journal")
        resp = Net::HTTP.get_response(uri)
        JSON.parse(resp.body) if resp.is_a?(Net::HTTPSuccess)
      end

      def on_message(pattern, content:)
        fixture = {
          match: message_match(pattern),
          response: { content: }
        }
        add_fixture(fixture)
      end

      def on_tool_result(tool_call_id, content:)
        fixture = {
          match: { toolCallId: tool_call_id },
          response: { content: }
        }
        add_fixture(fixture)
      end

      def add_catch_all_fixture(content: 'Default response')
        fixture = {
          match: {},
          response: { content: }
        }
        add_fixture(fixture)
      end

      private

      def message_match(pattern)
        case pattern
        when Regexp
          { userMessage: pattern.source }
        when String
          { userMessage: pattern }
        else
          {}
        end
      end

      def read_available_line
        @stdout.read_nonblock(4096)&.split("\n")&.find { |line| line.match(%r{http://}) }
      rescue IO::WaitReadable, EOFError
        nil
      end

      def aimock_installed?
        Dir.exist?(File.join(E2E_DIR, 'node_modules', '@copilotkit', 'aimock'))
      end

      def install_aimock
        output = Dir.chdir(E2E_DIR) { `npm install 2>&1` }
        $CHILD_STATUS.success? || raise("Failed to install e2e npm dependencies: #{output}")
      end
    end
  end
end

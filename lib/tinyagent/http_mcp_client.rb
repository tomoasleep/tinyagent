# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'securerandom'
require 'event_stream_parser'

module Tinyagent
  # Mcp client with HTTP transport.
  class HttpMcpClient
    attr_reader :base_url #: String
    attr_reader :headers #: Hash[String, String]
    attr_reader :session_id #: String?

    # @rbs url: String
    # @rbs headers: Hash[String, String]
    # @rbs session_id: String?
    def initialize(url:, headers: {}, session_id: nil) #: void
      @base_url = url
      @headers = headers
      @session_id = session_id

      @initialize_called = false
    end

    def initialize_session #: String?
      response = send_request(
        method: 'initialize',
        params: {
          protocolVersion: '2024-11-05',
          capabilities: {}, #: Hash[untyped, untyped]
          clientInfo: {
            name: 'tinyagent',
            version: '1.0'
          }
        }
      ).first

      @session_id = response['Mcp-Session-Id'] if response.is_a?(Hash) && response['Mcp-Session-Id']
      @initialize_called = true
      @session_id
    end

    def ping #: Array[Hash[String, untyped]]
      ensure_initialized
      send_request(method: 'ping')
    end

    def list_tools #: Array[Hash[String, untyped]]
      ensure_initialized
      results = send_request(method: 'tools/list')
      results.flat_map { |res| res.dig('result', 'tools') || [] }
    end

    # @rbs name: String
    # @rbs arguments: Hash[String, untyped]
    # @rbs &block: ? (Hash[String, untyped]) -> void
    def call_tool(name, arguments = {}, &) #: Array[Hash[String, untyped]]
      ensure_initialized
      results = send_request(
        method: 'tools/call',
        params: {
          name: name,
          arguments: arguments
        },
        &
      )

      results.flat_map { |res| res.dig('result', 'content') || [] }
    end

    def list_prompts #: Array[Hash[String, untyped]]
      ensure_initialized
      send_request(method: 'prompts/list')
    end

    # @rbs name: String
    # @rbs arguments: Hash[String, untyped]
    def get_prompt(name, arguments = {}) #: Array[Hash[String, untyped]]
      ensure_initialized
      send_request(
        method: 'prompts/get',
        params: {
          name: name,
          arguments: arguments
        }
      )
    end

    def list_resources #: Array[Hash[String, untyped]]
      ensure_initialized
      send_request(method: 'resources/list')
    end

    # @rbs uri: String
    def read_resource(uri) #: Array[Hash[String, untyped]]
      ensure_initialized
      send_request(
        method: 'resources/read',
        params: {
          uri: uri
        }
      )
    end

    def cleanup_session #: void
      if @session_id
        uri = URI.parse(@base_url)

        raise 'Invalid uri' if uri.host.nil?

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'

        request = Net::HTTP::Delete.new(uri.path.nil? || uri.path.empty? ? '/' : uri.path)
        request['Accept'] = 'application/json, text/event-stream'
        request['Content-Type'] = 'application/json'
        request['Mcp-Session-Id'] = @session_id
        headers.each { |k, v| request[k] = v }

        http.request(request)
        @session_id = nil
      end

      @initialize_called = false
    end

    private

    # @rbs @initialize_called: bool

    def ensure_initialized #: void
      return if @initialize_called || @session_id

      initialize_session
    end

    # @rbs method: String
    # @rbs params: Hash[String | Symbol, untyped]?
    # @rbs id: String?
    # @rbs &block: ? (Hash[String, untyped]) -> void
    def send_request(method:, params: nil, id: nil, &block) #: Array[Hash[String, untyped]]
      uri = URI.parse(@base_url)

      raise 'Invalid uri' if uri.host.nil?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.path.nil? || uri.path.empty? ? '/' : uri.path)
      request['Accept'] = 'application/json, text/event-stream'
      request['Content-Type'] = 'application/json'
      request['Mcp-Session-Id'] = @session_id if @session_id
      headers.each { |k, v| request[k] = v }

      body = {
        jsonrpc: '2.0',
        method: method,
        id: id || SecureRandom.uuid
      } #: Hash[Symbol, untyped]
      body[:params] = params if params

      request.body = JSON.generate(body)

      response = http.request(request)
      raise Error, "HTTP #{response.code}: #{response.body}" unless response.code.to_i == 200

      @session_id = response['Mcp-Session-Id'] if method == 'initialize'

      if response['Content-Type'] =~ %r{text/event-stream}
        handle_streaming_response(response, &block)
      else
        handle_response(response, &block)
      end
    rescue Net::HTTPExceptions, SystemCallError => e
      error_message = e.is_a?(StandardError) ? e.message : "Unknown error (#{e.class.name})"
      raise Error, "HTTP request failed: #{error_message}"
    end

    # @rbs response: Net::HTTPResponse
    # @rbs &block: ? (Hash[String, untyped]) -> void
    def handle_response(response, &block) #: Array[Hash[String, untyped]]
      result = JSON.parse(response.body)

      raise Error, "JSON-RPC Error #{result['error']['code']}: #{result['error']['message']}" if result['error']

      result['Mcp-Session-Id'] = response['Mcp-Session-Id'] if response['Mcp-Session-Id']

      block&.call(result)

      [result]
    end

    # @rbs response: Net::HTTPResponse
    # @rbs &block: ? (Hash[String, untyped]) -> void
    def handle_streaming_response(response, &block) #: Array[Hash[String, untyped]]
      events = [] #: Array[Hash[String, untyped]]
      parser = EventStreamParser::Parser.new

      body = response.body
      parser.feed(body) do |_type, data, _id, _reconnection_time|
        next if data.nil? || data.empty?

        begin
          parsed_data = JSON.parse(data)
          raise Error, "JSON-RPC Error #{parsed_data['error']['code']}: #{parsed_data['error']['message']}" if parsed_data['error']

          block&.call(parsed_data)

          events << parsed_data
        rescue JSON::ParserError => e
          raise Error, "Failed to parse SSE data: #{e.message}"
        end
      end

      events
    end

    class Error < Tinyagent::Error; end
  end
end

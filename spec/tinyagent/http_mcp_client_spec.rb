# frozen_string_literal: true

RSpec.describe Tinyagent::HttpMcpClient do
  include McpMockHelper

  let(:base_url) { 'http://localhost:5000' }

  describe '#initialize' do
    it 'stores base_url and headers' do
      client = described_class.new(url: base_url, headers: { 'X-Api-Key' => 'key123' })
      expect(client.base_url).to eq(base_url)
      expect(client.headers).to eq({ 'X-Api-Key' => 'key123' })
    end

    it 'defaults headers to empty hash' do
      client = described_class.new(url: base_url)
      expect(client.headers).to eq({})
    end

    it 'defaults session_id to nil' do
      client = described_class.new(url: base_url)
      expect(client.session_id).to be_nil
    end
  end

  describe '#initialize_session' do
    before do
      stub_mcp_initialize(base_url: base_url, session_id: 'session-123')
    end

    it 'sends initialize request and stores session id' do
      client = described_class.new(url: base_url)
      result = client.initialize_session
      expect(result).to eq('session-123')
      expect(client.session_id).to eq('session-123')
    end
  end

  describe '#ping' do
    before do
      stub_mcp_initialize(base_url: base_url)
      stub_mcp_ping(base_url: base_url)
    end

    it 'sends a ping request' do
      client = described_class.new(url: base_url)
      result = client.ping
      expect(result).to be_a(Array)
    end
  end

  describe '#list_tools' do
    before do
      stub_mcp_initialize(base_url: base_url)
      stub_mcp_list_tools(base_url: base_url, tools: [
                            { 'name' => 'tool1', 'description' => 'First tool' },
                            { 'name' => 'tool2', 'description' => 'Second tool' }
                          ])
    end

    it 'returns an array of tools' do
      client = described_class.new(url: base_url)
      tools = client.list_tools
      expect(tools.length).to eq(2)
      expect(tools.first['name']).to eq('tool1')
    end
  end

  describe '#call_tool' do
    before do
      stub_mcp_initialize(base_url: base_url)
      stub_mcp_call_tool(
        base_url: base_url,
        tool_name: 'add',
        response_content: [{ 'type' => 'text', 'text' => '3' }]
      )
    end

    it 'calls a tool and returns content' do
      client = described_class.new(url: base_url)
      result = client.call_tool('add', { 'a' => 1, 'b' => 2 })
      expect(result).to include({ 'type' => 'text', 'text' => '3' })
    end
  end

  describe '#call_tool with streaming' do
    before do
      stub_mcp_initialize(base_url: base_url)
      stub_mcp_call_tool_streaming(
        base_url: base_url,
        tool_name: 'stream_tool',
        streaming_chunks: [
          { 'content' => [{ 'type' => 'text', 'text' => 'chunk1' }] },
          { 'content' => [{ 'type' => 'text', 'text' => 'chunk2' }] }
        ]
      )
    end

    it 'handles SSE streaming responses' do
      client = described_class.new(url: base_url)
      result = client.call_tool('stream_tool')
      expect(result.length).to eq(2)
    end
  end

  describe '#cleanup_session' do
    before do
      stub_mcp_initialize(base_url: base_url, session_id: 'session-456')
    end

    it 'sends DELETE request and resets session' do
      client = described_class.new(url: base_url)
      client.initialize_session
      stub_mcp_cleanup_session(base_url: base_url, session_id: 'session-456')
      client.cleanup_session
      expect(client.session_id).to be_nil
    end
  end

  describe 'error handling' do
    it 'raises Tinyagent::Error on HTTP error' do
      stub_mcp_error(base_url: base_url, http_status: 500)
      client = described_class.new(url: base_url)
      expect { client.initialize_session }.to raise_error(Tinyagent::Error)
    end

    it 'raises Tinyagent::Error on JSON-RPC error' do
      stub_mcp_json_rpc_error(base_url: base_url, error_code: -32_601, error_message: 'Method not found')
      client = described_class.new(url: base_url)
      expect { client.initialize_session }.to raise_error(Tinyagent::Error, /JSON-RPC Error/)
    end
  end

  describe 'auto-initialization' do
    before do
      stub_mcp_initialize(base_url: base_url)
      stub_mcp_ping(base_url: base_url)
    end

    it 'auto-initializes when calling methods' do
      client = described_class.new(url: base_url)
      expect(client.session_id).to be_nil
      client.ping
    end
  end

  describe 'custom headers' do
    let(:custom_headers) { { 'Authorization' => 'Bearer token123' } }

    before do
      stub_mcp_initialize(base_url: base_url, headers: custom_headers)
    end

    it 'sends custom headers with requests' do
      client = described_class.new(url: base_url, headers: custom_headers)
      client.initialize_session
    end
  end
end

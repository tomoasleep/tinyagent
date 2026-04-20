# frozen_string_literal: true

RSpec.describe Tinyagent::UserMcpClient do
  include UserFactory
  include McpMockHelper

  let(:database) { create_database }
  let(:base_url) { 'http://localhost:4000' }
  let(:user) do
    create_user(database: database, mcp_configs: {
      'test_server' => { transport: 'http', url: base_url, headers: {} }
    })
  end
  let(:client) { described_class.new(user: user, mcp_name: 'test_server') }

  describe '#initialize' do
    it 'stores user and mcp_name' do
      expect(client.user).to eq(user)
      expect(client.mcp_name).to eq('test_server')
    end
  end

  describe '#configuration' do
    it 'returns the matching MCP configuration' do
      config = client.configuration
      expect(config).to be_a(Tinyagent::McpConfiguration)
      expect(config.name).to eq('test_server')
    end

    it 'raises when configuration not found' do
      bad_client = described_class.new(user: user, mcp_name: 'nonexistent')
      expect { bad_client.configuration }.to raise_error(RuntimeError, /MCP configuration not found/)
    end
  end

  describe '#list_tools' do
    before do
      stub_mcp_initialize(base_url: base_url)
      stub_mcp_list_tools(base_url: base_url, tools: [
        { 'name' => 'tool1', 'description' => 'Tool 1', 'inputSchema' => {} }
      ])
    end

    it 'returns tools from the MCP server' do
      tools = client.list_tools
      expect(tools.length).to eq(1)
      expect(tools.first['name']).to eq('tool1')
    end

    it 'caches the result' do
      tools1 = client.list_tools
      tools2 = client.list_tools
      expect(tools1).to eq(tools2)
    end
  end

  describe '#call_tool' do
    before do
      stub_mcp_initialize(base_url: base_url)
      stub_mcp_call_tool(
        base_url: base_url,
        tool_name: 'tool1',
        response_content: [{ 'type' => 'text', 'text' => 'result' }]
      )
    end

    it 'calls the tool and returns the result' do
      result = client.call_tool('tool1')
      expect(result).to include({ 'type' => 'text', 'text' => 'result' })
    end
  end

  describe '#ping' do
    before do
      stub_mcp_initialize(base_url: base_url)
      stub_mcp_ping(base_url: base_url)
    end

    it 'pings the server' do
      result = client.ping
      expect(result).to be_a(Array)
    end
  end

  describe '#initialize_session' do
    before do
      stub_mcp_initialize(base_url: base_url, session_id: 'session-abc')
    end

    it 'returns the session id' do
      session_id = client.initialize_session
      expect(session_id).to eq('session-abc')
    end
  end

  describe '#cleanup_session' do
    before do
      stub_mcp_initialize(base_url: base_url, session_id: 'session-abc')
    end

    it 'cleans up the session' do
      client.initialize_session
      stub_mcp_cleanup_session(base_url: base_url, session_id: 'session-abc')
      client.cleanup_session
    end
  end
end

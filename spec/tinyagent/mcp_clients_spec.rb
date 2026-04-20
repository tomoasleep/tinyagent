# frozen_string_literal: true

RSpec.describe Tinyagent::McpClients do
  include McpMockHelper

  describe '#initialize' do
    it 'stores clients' do
      clients = described_class.new([])
      expect(clients.clients).to eq([])
    end
  end

  describe '#any?' do
    it 'returns false with no clients' do
      clients = described_class.new([])
      expect(clients.any?).to be false
    end

    it 'returns true with clients' do
      db = Tinyagent::Database.new(Struct.new(:data).new({ Tinyagent::Database::NAMESPACE => {} }))
      user = Tinyagent::User.new(database: db, id: 'user1')
      client = Tinyagent::UserMcpClient.new(user: user, mcp_name: 'test')
      clients = described_class.new([client])
      expect(clients.any?).to be true
    end
  end

  describe '#available_tools' do
    it 'returns empty array when no clients' do
      clients = described_class.new([])
      expect(clients.available_tools).to eq([])
    end

    context 'with a configured client' do
      let(:base_url) { 'http://localhost:4000' }
      let(:db) { Tinyagent::Database.new(Struct.new(:data).new({ Tinyagent::Database::NAMESPACE => {} })) }
      let(:user) do
        Tinyagent::User.new(database: db, id: 'user1')
      end
      let(:mcp_config) do
        Tinyagent::McpConfiguration.new(
          name: 'test_server',
          transport: :http,
          url: base_url,
          headers: {}
        )
      end
      let(:user_mcp_client) { Tinyagent::UserMcpClient.new(user: user, mcp_name: 'test_server') }

      before do
        user.mcp_configurations.add(mcp_config)

        stub_mcp_initialize(base_url: base_url)
        stub_mcp_list_tools(base_url: base_url, tools: [
          { 'name' => 'add', 'description' => 'Add numbers', 'inputSchema' => { 'type' => 'object' } }
        ])
      end

      it 'returns tools from clients with prefixed names' do
        clients = described_class.new([user_mcp_client])
        tools = clients.available_tools
        expect(tools.length).to eq(1)
        expect(tools.first.name).to eq('mcp_test_server__add')
      end

      it 'returns Tool instances' do
        clients = described_class.new([user_mcp_client])
        tools = clients.available_tools
        expect(tools.first).to be_a(Tinyagent::Tool)
      end
    end

    context 'when a client raises an error' do
      let(:base_url) { 'http://localhost:4001' }
      let(:db) { Tinyagent::Database.new(Struct.new(:data).new({ Tinyagent::Database::NAMESPACE => {} })) }
      let(:user) { Tinyagent::User.new(database: db, id: 'user1') }
      let(:mcp_config) do
        Tinyagent::McpConfiguration.new(
          name: 'broken_server',
          transport: :http,
          url: base_url,
          headers: {}
        )
      end
      let(:user_mcp_client) { Tinyagent::UserMcpClient.new(user: user, mcp_name: 'broken_server') }

      before do
        user.mcp_configurations.add(mcp_config)
        stub_mcp_error(base_url: base_url, http_status: 500)
      end

      it 'gracefully handles errors and returns empty for that client' do
        clients = described_class.new([user_mcp_client])
        expect { clients.available_tools }.not_to raise_error
      end
    end
  end
end

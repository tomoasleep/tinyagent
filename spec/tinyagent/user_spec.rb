# frozen_string_literal: true

RSpec.describe Tinyagent::User do
  include UserFactory

  let(:database) { create_database }

  describe '.find_or_create' do
    it 'creates a new User' do
      user = described_class.find_or_create(database: database, id: 'user1')
      expect(user).to be_a(described_class)
      expect(user.id).to eq('user1')
    end
  end

  describe '#initialize' do
    it 'sets database and id' do
      user = described_class.new(database: database, id: 'test_user')
      expect(user.database).to eq(database)
      expect(user.id).to eq('test_user')
    end
  end

  describe '#mcp_configurations' do
    it 'returns a UserMcpConfigurations instance' do
      user = described_class.new(database: database, id: 'user1')
      expect(user.mcp_configurations).to be_a(Tinyagent::UserMcpConfigurations)
    end

    it 'memoizes the configurations' do
      user = described_class.new(database: database, id: 'user1')
      expect(user.mcp_configurations).to equal(user.mcp_configurations)
    end
  end

  describe '#ai_memories' do
    it 'returns a UserAiMemories instance' do
      user = described_class.new(database: database, id: 'user1')
      expect(user.ai_memories).to be_a(Tinyagent::UserAiMemories)
    end

    it 'memoizes the ai_memories' do
      user = described_class.new(database: database, id: 'user1')
      expect(user.ai_memories).to equal(user.ai_memories)
    end
  end

  describe '#system_prompt' do
    it 'returns nil when not set' do
      user = create_user(database: database)
      expect(user.system_prompt).to be_nil
    end

    it 'returns the stored system prompt' do
      user = create_user(database: database)
      user.system_prompt = 'You are helpful'
      expect(user.system_prompt).to eq('You are helpful')
    end
  end

  describe '#mcp_clients' do
    it 'returns an empty array when no configurations' do
      user = described_class.new(database: database, id: 'user1')
      expect(user.mcp_clients).to eq([])
    end

    it 'returns UserMcpClient instances for each configuration' do
      user = create_user(database: database, mcp_configs: {
        'server1' => { transport: 'http', url: 'http://localhost:3000' }
      })
      clients = user.mcp_clients
      expect(clients.length).to eq(1)
      expect(clients.first).to be_a(Tinyagent::UserMcpClient)
    end
  end

  describe '#mcp_tools_caches' do
    it 'returns a UserMcpToolsCaches instance' do
      user = described_class.new(database: database, id: 'user1')
      expect(user.mcp_tools_caches).to be_a(Tinyagent::UserMcpToolsCaches)
    end
  end
end

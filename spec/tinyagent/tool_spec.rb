# frozen_string_literal: true

RSpec.describe Tinyagent::Tool do
  describe '#initialize' do
    it 'stores name, title, description, and input_schema', :aggregate_failures do
      tool = described_class.new(
        name: 'calculator',
        title: 'Calculator',
        description: 'Performs calculations',
        input_schema: { 'type' => 'object' }
      )
      expect(tool.name).to eq('calculator')
      expect(tool.title).to eq('Calculator')
      expect(tool.description).to eq('Performs calculations')
      expect(tool.input_schema).to eq({ 'type' => 'object' })
    end

    it 'accepts a block for on_call' do
      tool = described_class.new(
        name: 'echo',
        title: 'Echo',
        description: 'Echoes input',
        input_schema: {}, &:to_s
      )

      expect(tool.on_call).not_to be_nil
    end

    it 'defaults silent to false', :aggregate_failures do
      tool = described_class.new(
        name: 'test', title: 'Test', description: 'Test', input_schema: {}
      )
      expect(tool.silent).to be false
      expect(tool.silent?).to be false
    end

    it 'accepts silent option' do
      tool = described_class.new(
        name: 'test', title: 'Test', description: 'Test', input_schema: {}, silent: true
      )
      expect(tool.silent?).to be true
    end
  end

  describe '#call' do
    it 'invokes the on_call block with params' do
      tool = described_class.new(
        name: 'echo',
        title: 'Echo',
        description: 'Echoes',
        input_schema: {}
      ) { |params| "echo: #{params['msg']}" }

      result = tool.call({ 'msg' => 'hello' })
      expect(result).to eq('echo: hello')
    end

    it 'returns nil when no block is given' do
      tool = described_class.new(
        name: 'test', title: 'Test', description: 'Test', input_schema: {}
      )
      expect(tool.call({})).to be_nil
    end
  end
end

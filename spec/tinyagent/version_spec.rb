# frozen_string_literal: true

RSpec.describe Tinyagent::VERSION do
  it 'is a string' do
    expect(described_class).to be_a(String)
  end

  it 'follows semantic versioning format' do
    expect(described_class).to match(/\A\d+\.\d+\.\d+(\.\w+)?\z/)
  end
end

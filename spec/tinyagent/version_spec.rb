# frozen_string_literal: true

RSpec.describe 'Tinyagent::VERSION' do
  subject(:version) { Object.const_get(self.class.description) }

  it 'is a string' do
    expect(version).to be_a(String)
  end

  it 'follows semantic versioning format' do
    expect(version).to match(/\A\d+\.\d+\.\d+(\.\w+)?\z/)
  end
end

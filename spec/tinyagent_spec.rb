# frozen_string_literal: true

RSpec.describe Tinyagent do
  it 'has a version number' do
    expect(Tinyagent::VERSION).not_to be_nil
  end

  it 'has a VERSION constant' do
    expect(Tinyagent::VERSION).to be_a(String)
  end

  it 'defines an Error class' do
    expect(Tinyagent::Error).to be < StandardError
  end

  it 'loads without errors' do
    expect { Tinyagent }.not_to raise_error
  end
end

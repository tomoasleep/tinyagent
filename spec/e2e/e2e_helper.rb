# frozen_string_literal: true

require 'bundler/setup'
require 'tinyagent'
require 'securerandom'
require 'webmock'
require_relative '../support/e2e/aimock_helper'
require_relative '../support/e2e/tuistory_helper'

WebMock.allow_net_connect!

RSpec.shared_context 'e2e' do
  let(:aimock) { $aimock_server }

  let(:session) do
    name = "test-#{$$}-#{SecureRandom.hex(4)}"
    E2E::TuistoryHelper::Session.new(name:, aimock_url: aimock.v1_url)
  end

  after do
    session&.close
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_e2e_status'
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    $aimock_server = E2E::AimockHelper::AimockServer.new
    $aimock_server.start
  end

  config.after(:suite) do
    $aimock_server&.stop
  end

  config.before do
    $aimock_server&.clear_fixtures
  end

  config.include_context 'e2e', type: :e2e
end

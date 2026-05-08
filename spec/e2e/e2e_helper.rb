# frozen_string_literal: true

require 'bundler/setup'
require 'tinyagent'
require 'securerandom'
require 'english'
require 'webmock'
require_relative '../support/e2e/aimock_helper'
require_relative '../support/e2e/tuistory_helper'
require_relative '../support/e2e/matchers/match_screen'
require_relative '../support/snapshot_helper'

WebMock.allow_net_connect!

RSpec.shared_context 'when e2e' do
  include ScreenMatching

  let(:aimock) { E2E::AimockHelper::AimockServer.instance }

  let(:screen_size) { { cols: 120, rows: 36 } }

  let(:session) do
    name = "test-#{$PROCESS_ID}-#{SecureRandom.hex(4)}"
    E2E::TuistoryHelper::Session.new(name:, aimock_url: aimock.v1_url, **screen_size)
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
    E2E::AimockHelper::AimockServer.instance.start
  end

  config.after(:suite) do
    E2E::AimockHelper::AimockServer.instance&.stop
  end

  config.after do
    if ENV['DEBUG'] && RSpec.current_example&.exception
      warn "\n--- AIMock logs ---"
      E2E::AimockHelper::AimockServer.instance&.logs&.each { |line| warn line }
      warn "--- End AIMock logs ---\n"
    end
    E2E::AimockHelper::AimockServer.instance&.clear_fixtures
  end

  config.include_context 'when e2e', type: :e2e
end

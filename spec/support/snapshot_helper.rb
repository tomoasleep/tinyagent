# frozen_string_literal: true

RSpec.configure do |config|
  config.after(:suite) do
    if ENV['UPDATE_SNAPSHOT'] && !ScreenMatching.snapshot_updates.empty?
      ScreenMatching.update_snapshots!
      count = ScreenMatching.snapshot_updates.length
      files = ScreenMatching.snapshot_updates.map { |u| u[:file] }.uniq
      warn "\n[UPDATE_SNAPSHOT] Updated #{count} snapshot(s) in #{files.length} file(s)"
    end
  end
end

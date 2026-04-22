# frozen_string_literal: true

module Tinyagent
  # Manage migrations
  module Migrations
    def self.run #: void
      Sequel.extension :migration
      migrations_dir = File.join(File.dirname(__FILE__), 'migrations')
      Sequel::Migrator.run(DB, migrations_dir)
    end
  end
end

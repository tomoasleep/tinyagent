# frozen_string_literal: true

require 'dry/cli'
require 'tinyagent/tui/core'
require 'tinyagent/tui/chat'

module Tinyagent
  module Cli
    module Commands
      # Launches the interactive Chat TUI.
      class Tui < Dry::CLI::Command
        desc 'Start TUI chat'

        def call(*) #: void
          Migrations.run
          Tinyagent::Tui::Program.new(model: Tinyagent::Tui::Chat.new, alt_screen: true).start
        end
      end
    end
  end
end

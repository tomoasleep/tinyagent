# frozen_string_literal: true

require 'dry/cli'
require 'bubbletea'
require 'tinyagent/tui/chat'

module Tinyagent
  module Cli
    module Commands
      # Launches the interactive Chat TUI.
      class Tui < Dry::CLI::Command
        desc 'Start TUI chat'

        def call(*) #: void
          Migrations.run
          Bubbletea.run(Tinyagent::Tui::Chat.new, alt_screen: true)
        end
      end
    end
  end
end

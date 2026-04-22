# frozen_string_literal: true

require 'dry/cli'
require 'bubbletea'
require 'lipgloss'

module Tinyagent
  module Cli
    module Commands
      class Tui < Dry::CLI::Command
        desc 'Start TUI chat'

        def call
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'dry/cli'

module Tinyagent
  module Cli
    # Define cli commands in this module.
    module Commands
      extend Dry::CLI::Registry

      def self.run #: void
        Dry::CLI.new(Tinyagent::Cli::Commands).call
      end

      require_relative 'commands/tui'

      register 'tui', Tui
    end
  end
end

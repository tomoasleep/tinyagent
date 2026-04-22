# frozen_string_literal: true

require 'dry/cli'

module Tinyagent
  # Define cli Handlers in this module
  module Cli
    autoload :Commands, 'tinyagent/cli/commands'
  end
end

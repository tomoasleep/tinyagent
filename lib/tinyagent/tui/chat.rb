# frozen_string_literal: true

require 'bubbletea'
require 'lipgloss'

module Tinyagent
  module Tui
    class Chat
      include Bubbletea::Model

      def initialize
        @thread = Thread.create
      end
    end
  end
end

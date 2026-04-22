# frozen_string_literal: true

require 'bubbletea'
require 'lipgloss'

module Tinyagent
  module Tui
    class Chat
      include Bubbletea::Model

      def initialize
        @chat_thread = ChatThread.new
      end
    end
  end
end

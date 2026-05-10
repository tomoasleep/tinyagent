# frozen_string_literal: true

require 'pastel'
require 'unicode/display_width'

module Tinyagent
  module Tui
    # Utility helpers for stripping ANSI codes and measuring terminal text.
    module Ansi
      PASTEL = Pastel.new(enabled: true)

      module_function

      # @rbs text: String
      def strip(text) #: String
        PASTEL.strip(text)
      end

      # @rbs text: String
      def display_width(text) #: Integer
        stripped = strip(text)
        return 0 if stripped.empty?

        stripped.lines.map { |line| Unicode::DisplayWidth.of(line.chomp) }.max || 0
      end

      # @rbs text: String
      def display_height(text) #: Integer
        return 0 if text.nil? || text.empty?

        stripped = strip(text)
        stripped.lines.count
      end
    end
  end
end

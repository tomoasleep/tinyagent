# frozen_string_literal: true

require 'pastel'
require_relative 'ansi'

module Tinyagent
  module Tui
    # Selectable list component for palette and picker UIs.
    class List
      SELECTED_MARKER = '>'
      DESELECTED_MARKER = ' '

      attr_accessor :width #: Integer
      attr_accessor :height #: Integer
      attr_accessor :show_title #: bool
      attr_accessor :show_filter #: bool
      attr_accessor :show_pagination #: bool
      attr_accessor :show_status_bar #: bool
      attr_accessor :fill_height #: bool
      attr_reader :items #: Array[untyped]
      attr_reader :selected_index #: Integer

      # @rbs @pastel: untyped

      # @rbs items: Array[untyped]
      # @rbs width: Integer
      # @rbs height: Integer
      def initialize(items, width:, height:) #: void
        @items = items
        @width = width
        @height = height
        @selected_index = 0
        @show_title = true
        @show_filter = true
        @show_pagination = true
        @show_status_bar = true
        @fill_height = true
        @pastel = Pastel.new
      end

      # @rbs index: Integer
      def select(index) #: Integer
        @selected_index = index.clamp(0, @items.length - 1)
      end

      def selected_item #: untyped
        @items[@selected_index]
      end

      def select_prev #: Integer
        if @selected_index.positive?
          @selected_index -= 1
        else
          @selected_index = @items.length - 1
        end
      end

      def select_next #: Integer
        if @selected_index < @items.length - 1
          @selected_index += 1
        else
          @selected_index = 0
        end
      end

      def visible_items #: Array[untyped]
        return @items if @height <= 0 || @items.length <= @height

        start_index = [@selected_index - @height + 1, 0].max
        @items[start_index, @height] || []
      end

      # @rbs new_items: Array[untyped]
      def items=(new_items) #: Integer
        @items = new_items
        @selected_index = 0
      end

      def view #: String
        visible = visible_items
        first_visible_item = visible.first
        first_visible_index = first_visible_item ? (@items.index(first_visible_item) || 0) : 0
        lines = visible.each_with_index.map do |item, i|
          absolute_index = first_visible_index + i
          marker = absolute_index == @selected_index ? SELECTED_MARKER : DESELECTED_MARKER
          title = item.is_a?(Hash) ? item[:title] : item.to_s
          line = "#{marker} #{title}"
          if absolute_index == @selected_index
            @pastel.decorate(line, :bold)
          else
            line
          end
        end

        lines.join("\n")
      end
    end
  end
end

# frozen_string_literal: true

require 'tinyagent/tui/core'
require 'tinyagent/tui/components'

module Tinyagent
  module Tui
    class Chat
      # Renders palette/model-select overlay views on top of viewport content.
      class PaletteView
        PALETTE_WIDTH = 36

        # @rbs viewport_content: String
        # @rbs width: Integer
        # @rbs height: Integer
        # @rbs list: Tinyagent::Tui::List
        # @rbs filter_input: Tinyagent::Tui::TextInput
        def palette_overlay_view(viewport_content, width, height, list, filter_input) #: String
          generic_overlay_view(viewport_content, width, height, list, filter_input)
        end

        # @rbs viewport_content: String
        # @rbs width: Integer
        # @rbs height: Integer
        # @rbs list: Tinyagent::Tui::List
        # @rbs filter_input: Tinyagent::Tui::TextInput
        def model_select_overlay_view(viewport_content, width, height, list, filter_input) #: String
          generic_overlay_view(viewport_content, width, height, list, filter_input)
        end

        private

        # @rbs viewport_content: String
        # @rbs width: Integer
        # @rbs height: Integer
        # @rbs list: Tinyagent::Tui::List
        # @rbs filter_input: Tinyagent::Tui::TextInput
        def generic_overlay_view(viewport_content, width, height, list, filter_input) #: String
          viewport_height = [height - 3, 1].max
          max_list_height = [viewport_height - 4, 1].max
          list.height = [list.visible_items.length, max_list_height].min

          inner_lines = []
          inner_lines << filter_input.view
          inner_lines << list.view
          inner_lines << Tinyagent::Tui::Style.new.foreground('241').render('esc to close')
          inner = inner_lines.join("\n")

          box_style = Tinyagent::Tui::Style.new
                                           .border(Tinyagent::Tui::Style::ROUNDED_BORDER)
                                           .padding(0, 2)
                                           .width(PALETTE_WIDTH)

          palette_box = box_style.render(inner)
          palette_w = Tinyagent::Tui::Style.width(palette_box)
          palette_h = Tinyagent::Tui::Style.height(palette_box)

          vp_lines = if viewport_content.include?("\n")
                       viewport_content.split("\n")
                     else
                       viewport_content.split('\\n')
                     end
          vp_lines << '' while vp_lines.length < viewport_height

          overlay_x = [((width - palette_w) + 1) / 2, 0].max

          last_content_line = vp_lines.rindex { |l| Tinyagent::Tui::Ansi.strip(l).strip != '' }
          overlay_y = last_content_line ? [last_content_line - palette_h + 2, 0].max : 0
          max_y = [viewport_height - palette_h, 0].max
          overlay_y = [overlay_y, max_y].min

          dim_style = Tinyagent::Tui::Style.new.foreground('244')

          palette_lines = palette_box.split("\n")
          palette_lines.each_with_index do |pl, i|
            target_y = overlay_y + i
            break if target_y >= vp_lines.length

            plain = Tinyagent::Tui::Ansi.strip(vp_lines[target_y]).ljust(width)
            dim_left = dim_style.render(plain[0, overlay_x] || '')
            dim_right = dim_style.render(plain[overlay_x + palette_w, width - overlay_x - palette_w] || '')
            vp_lines[target_y] = dim_left + pl + dim_right
          end

          vp_lines.join("\n")
        end
      end
    end
  end
end

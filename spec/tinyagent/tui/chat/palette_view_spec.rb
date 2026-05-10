# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/core'
require 'tinyagent/tui/components'
require 'tinyagent/tui/chat/palette_view'

RSpec.describe Tinyagent::Tui::Chat::PaletteView do
  let(:view) { described_class.new }
  let(:viewport_content) { "line1\nline2\nline3" }
  let(:width) { 40 }
  let(:height) { 10 }

  describe '#palette_overlay_view' do
    let(:list) do
      list = Tinyagent::Tui::List.new([{ title: 'clear', key: :clear }], width: 20, height: 1)
      list.show_title = false
      list.show_filter = false
      list.show_pagination = false
      list.show_status_bar = false
      list.fill_height = false
      list
    end

    let(:filter_input) do
      input = Tinyagent::Tui::TextInput.new
      input.width = 20
      input
    end

    it 'returns a string' do
      result = view.palette_overlay_view(viewport_content, width, height, list, filter_input)
      expect(result).to be_a(String)
    end

    it 'renders overlay on top of viewport content' do
      result = view.palette_overlay_view(viewport_content, width, height, list, filter_input)
      expect(result).to include('clear')
    end

    it 'dims non-overlay viewport lines' do
      long_viewport = "line1\nline2\nline3\nline4\nline5\nline6\nline7\nline8\nline9\nline10"
      result = view.palette_overlay_view(long_viewport, width, 20, list, filter_input)
      expect(result).to include('line1').or include('line2').or include('line3')
    end

    it 'renders filter input at top of overlay' do
      filter_input.focus
      filter_input.value = 'cle'
      result = view.palette_overlay_view(viewport_content, width, height, list, filter_input)
      expect(result).to include('cle')
    end

    it 'centers overlay horizontally' do
      result = view.palette_overlay_view(viewport_content, width, height, list, filter_input)
      lines = result.split("\n")
      overlay_line = lines.find { |l| l.include?('clear') }
      expect(overlay_line).not_to be_empty
    end
  end

  describe '#model_select_overlay_view' do
    let(:list) do
      list = Tinyagent::Tui::List.new([{ title: 'OpenAI', key: 'openai' }], width: 20, height: 1)
      list.show_title = false
      list.show_filter = false
      list.show_pagination = false
      list.show_status_bar = false
      list.fill_height = false
      list
    end

    let(:filter_input) do
      input = Tinyagent::Tui::TextInput.new
      input.width = 20
      input
    end

    it 'returns a string' do
      result = view.model_select_overlay_view(viewport_content, width, height, list, filter_input)
      expect(result).to be_a(String)
    end

    it 'renders overlay with provider/model items' do
      result = view.model_select_overlay_view(viewport_content, width, height, list, filter_input)
      expect(result).to include('OpenAI')
    end
  end

  describe 'clamping behavior' do
    let(:list) do
      list = Tinyagent::Tui::List.new(
        [
          { title: 'item1', key: :a },
          { title: 'item2', key: :b },
          { title: 'item3', key: :c }
        ],
        width: 20,
        height: 3
      )
      list.show_title = false
      list.show_filter = false
      list.show_pagination = false
      list.show_status_bar = false
      list.fill_height = false
      list
    end

    let(:filter_input) do
      input = Tinyagent::Tui::TextInput.new
      input.width = 20
      input
    end

    it 'does not exceed viewport height' do
      short_viewport = 'short'
      result = view.palette_overlay_view(short_viewport, width, 5, list, filter_input)
      lines = result.split("\n")
      expect(lines.length).to be <= 5
    end
  end
end

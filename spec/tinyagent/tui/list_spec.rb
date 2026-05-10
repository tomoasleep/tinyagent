# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/components/list'

RSpec.describe Tinyagent::Tui::List do
  let(:items) do
    [
      { title: 'clear', key: :clear },
      { title: 'compact', key: :compact },
      { title: 'usage', key: :usage },
      { title: 'change model', key: :change_model }
    ]
  end

  describe '#initialize' do
    it 'creates a list with items' do
      list = described_class.new(items, width: 30, height: 4)
      expect([list.items, list.width, list.height]).to eq([items, 30, 4])
    end
  end

  describe '#select' do
    it 'sets the selected index' do
      list = described_class.new(items, width: 30, height: 4)
      list.select(2)
      expect(list.selected_index).to eq(2)
    end
  end

  describe '#selected_item' do
    it 'returns the currently selected item' do
      list = described_class.new(items, width: 30, height: 4)
      list.select(1)
      expect(list.selected_item).to eq(title: 'compact', key: :compact)
    end
  end

  describe '#select_prev / #select_next' do
    it 'moves selection up' do
      list = described_class.new(items, width: 30, height: 4)
      list.select(1)
      list.select_prev
      expect(list.selected_index).to eq(0)
    end

    it 'wraps around when moving up from first item' do
      list = described_class.new(items, width: 30, height: 4)
      list.select(0)
      list.select_prev
      expect(list.selected_index).to eq(3)
    end

    it 'moves selection down' do
      list = described_class.new(items, width: 30, height: 4)
      list.select(0)
      list.select_next
      expect(list.selected_index).to eq(1)
    end

    it 'wraps around when moving down from last item' do
      list = described_class.new(items, width: 30, height: 4)
      list.select(3)
      list.select_next
      expect(list.selected_index).to eq(0)
    end
  end

  describe '#items=' do
    it 'replaces items and resets selection' do
      list = described_class.new(items, width: 30, height: 4)
      list.select(2)
      new_items = [{ title: 'new', key: :new }]
      list.items = new_items
      expect([list.items, list.selected_index]).to eq([new_items, 0])
    end
  end

  describe '#view' do
    it 'renders the list with selected item highlighted' do
      list = described_class.new(items, width: 30, height: 4)
      list.select(0)
      view = Tinyagent::Tui::Ansi.strip(list.view)
      expect(view).to match(/^> clear/)
    end

    it 'shows all items' do
      list = described_class.new(items, width: 30, height: 4)
      view = list.view
      expect(view).to match(/clear.*compact/m)
    end

    it 'limits rendered items to the configured height' do
      list = described_class.new(items, width: 30, height: 2)

      view = Tinyagent::Tui::Ansi.strip(list.view)

      expect(view.split("\n")).to eq(['> clear', '  compact'])
    end
  end

  describe 'display options' do
    it 'hides title when show_title is false' do
      list = described_class.new(items, width: 30, height: 4)
      list.show_title = false
      expect(list.show_title).to be false
    end

    it 'hides filter when show_filter is false' do
      list = described_class.new(items, width: 30, height: 4)
      list.show_filter = false
      expect(list.show_filter).to be false
    end

    it 'hides pagination when show_pagination is false' do
      list = described_class.new(items, width: 30, height: 4)
      list.show_pagination = false
      expect(list.show_pagination).to be false
    end

    it 'hides status bar when show_status_bar is false' do
      list = described_class.new(items, width: 30, height: 4)
      list.show_status_bar = false
      expect(list.show_status_bar).to be false
    end

    it 'sets fill_height' do
      list = described_class.new(items, width: 30, height: 4)
      list.fill_height = false
      expect(list.fill_height).to be false
    end
  end
end

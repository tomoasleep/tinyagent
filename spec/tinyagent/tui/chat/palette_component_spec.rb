# frozen_string_literal: true

require 'spec_helper'
require 'bubbles'
require_relative '../../../support/key_helper'

RSpec.describe Tinyagent::Tui::Chat::PaletteComponent do
  include KeyHelper

  let(:component) { described_class.new }
  let(:viewport_content) { "line1\nline2\nline3" }
  let(:width) { 40 }
  let(:height) { 10 }

  describe '#init' do
    it 'returns model and no command', :aggregate_failures do
      model, cmd = component.init
      expect(model).to be_a(described_class)
      expect(cmd).to be_nil
    end
  end

  describe '#open' do
    it 'transitions to command state' do
      component.open
      expect(component.command_state?).to be true
    end

    it 'resets filter input' do
      component.open
      # Filter input should be focused after open
      expect(component.filter_input_focused?).to be true
    end
  end

  describe '#update in command state' do
    before { component.open }

    it 'closes on esc' do
      updated, _cmd = component.update(key('esc'))
      expect(updated.closed?).to be true
    end

    it 'closes on ctrl+p' do
      updated, _cmd = component.update(key('ctrl+p'))
      expect(updated.closed?).to be true
    end

    it 'navigates with down key' do
      updated, _cmd = component.update(key('down'))
      expect(updated.selected_index).to eq(1)
    end

    it 'navigates with j key' do
      updated, _cmd = component.update(key('j'))
      expect(updated.selected_index).to eq(1)
    end

    it 'navigates with k key' do
      component.update(key('j'))
      updated, _cmd = component.update(key('k'))
      expect(updated.selected_index).to eq(0)
    end

    it 'selects command on enter', :aggregate_failures do
      updated, _cmd = component.update(key('enter'))
      expect(updated.closed?).to be true
      expect(updated.selected_command_key).to eq(:clear)
    end

    it 'transitions to provider_select on change_model command' do
      # Navigate to change_model (last item)
      3.times { component.update(key('down')) }
      updated, _cmd = component.update(key('enter'))
      expect(updated.provider_select_state?).to be true
    end

    it 'filters commands with typing', :aggregate_failures do
      component.update(key('c'))
      component.update(key('l'))
      expect(component.filtered_items.length).to eq(2)
      expect(component.filtered_items.first[:title]).to eq('clear')
    end

    it 'shows all items when filter is empty' do
      component.update(key('z'))
      component.update(key('esc'))
      component.open
      expect(component.filtered_items.length).to eq(4)
    end
  end

  describe '#update in provider_select state' do
    before do
      component.open
      # Navigate to change_model and select it
      3.times { component.update(key('down')) }
      component.update(key('enter'))
    end

    it 'closes on esc' do
      updated, _cmd = component.update(key('esc'))
      expect(updated.closed?).to be true
    end

    it 'transitions to model_select on enter' do
      updated, _cmd = component.update(key('enter'))
      expect(updated.model_select_state?).to be true
    end

    it 'filters providers with typing' do
      # Type some characters to filter
      component.update(key('o'))
      expect(component.filtered_items.length).to be >= 1
    end
  end

  describe '#update in model_select state' do
    before do
      component.open
      # Navigate to change_model and select it
      3.times { component.update(key('down')) }
      component.update(key('enter'))
      # Select first provider
      component.update(key('enter'))
    end

    it 'closes on esc' do
      updated, _cmd = component.update(key('esc'))
      expect(updated.closed?).to be true
    end

    it 'selects model on enter', :aggregate_failures do
      updated, _cmd = component.update(key('enter'))
      expect(updated.closed?).to be true
      expect(updated.selected_model).not_to be_nil
      expect(updated.selected_model).not_to be_empty
      expect(updated.selected_provider).not_to be_nil
      expect(updated.selected_provider).not_to be_empty
    end
  end

  describe '#view in command state' do
    before { component.open }

    it 'returns a string' do
      result = component.view(viewport_content, width, height)
      expect(result).to be_a(String)
    end

    it 'renders overlay on top of viewport content' do
      result = component.view(viewport_content, width, height)
      expect(result).to include('clear')
    end

    it 'dims non-overlay viewport lines' do
      long_viewport = "line1\nline2\nline3\nline4\nline5\nline6\nline7\nline8\nline9\nline10"
      result = component.view(long_viewport, width, 20)
      expect(result).to include('line1').or include('line2').or include('line3')
    end

    it 'does not exceed viewport height' do
      short_viewport = 'short'
      result = component.view(short_viewport, width, 5)
      lines = result.split("\n")
      expect(lines.length).to be <= 5
    end
  end

  describe '#view in provider_select state' do
    before do
      component.open
      3.times { component.update(key('down')) }
      component.update(key('enter'))
    end

    it 'returns a string' do
      result = component.view(viewport_content, width, height)
      expect(result).to be_a(String)
    end

    it 'renders provider items' do
      result = component.view(viewport_content, width, height)
      # Should include at least one provider name
      expect(result).not_to eq(viewport_content)
    end
  end

  describe '#view in model_select state' do
    before do
      component.open
      3.times { component.update(key('down')) }
      component.update(key('enter'))
      component.update(key('enter'))
    end

    it 'returns a string' do
      result = component.view(viewport_content, width, height)
      expect(result).to be_a(String)
    end

    it 'renders model items' do
      result = component.view(viewport_content, width, height)
      expect(result).not_to eq(viewport_content)
    end
  end
end

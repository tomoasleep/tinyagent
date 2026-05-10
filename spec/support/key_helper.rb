# frozen_string_literal: true

require 'spec_helper'
require 'tinyagent/tui/core/key_message'
require 'tinyagent/tui/core/window_size_message'

module KeyHelper
  def key(name, alt: false)
    key_type = case name
               when 'enter' then Tinyagent::Tui::KeyMessage::KEY_ENTER
               when 'esc' then Tinyagent::Tui::KeyMessage::KEY_ESC
               when 'up' then Tinyagent::Tui::KeyMessage::KEY_UP
               when 'down' then Tinyagent::Tui::KeyMessage::KEY_DOWN
               when 'tab' then Tinyagent::Tui::KeyMessage::KEY_TAB
               when 'backspace' then Tinyagent::Tui::KeyMessage::KEY_BACKSPACE
               when 'ctrl+c' then Tinyagent::Tui::KeyMessage::KEY_CTRL_C
               when 'ctrl+p' then Tinyagent::Tui::KeyMessage::KEY_CTRL_P
               when 'ctrl+m' then Tinyagent::Tui::KeyMessage::KEY_NULL
               else
                 Tinyagent::Tui::KeyMessage::KEY_RUNES
               end
    runes = key_type == Tinyagent::Tui::KeyMessage::KEY_RUNES ? name.chars.map(&:ord) : []
    Tinyagent::Tui::KeyMessage.create(key_type: key_type, runes: runes, alt: alt, name: name)
  end

  def resize(width, height)
    Tinyagent::Tui::WindowSizeMessage.new(width: width, height: height)
  end

  def type_text(chat, text)
    text.each_char { |c| chat.update(key(c)) }
  end

  def submit_text(chat, text)
    type_text(chat, text)
    chat.update(key('enter'))
  end

  def select_provider_and_model(chat)
    chat.update(key('ctrl+p'))
    type_text(chat, 'ch')
    chat.update(key('enter'))
    chat.update(key('down'))
    chat.update(key('enter'))
    chat.update(key('enter'))
  end
end

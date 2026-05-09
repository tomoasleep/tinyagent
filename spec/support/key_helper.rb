# frozen_string_literal: true

require 'bubbletea'
require 'bubbles'

module KeyHelper
  def key(name, alt: false)
    key_type = case name
               when 'enter' then Bubbletea::KeyMessage::KEY_ENTER
               when 'esc' then Bubbletea::KeyMessage::KEY_ESC
               when 'up' then Bubbletea::KeyMessage::KEY_UP
               when 'down' then Bubbletea::KeyMessage::KEY_DOWN
               when 'tab' then Bubbletea::KeyMessage::KEY_TAB
               when 'backspace' then Bubbletea::KeyMessage::KEY_BACKSPACE
               when 'ctrl+c' then Bubbletea::KeyMessage::KEY_CTRL_C
               when 'ctrl+p' then Bubbletea::KeyMessage::KEY_CTRL_P
               when 'ctrl+m' then Bubbletea::KeyMessage::KEY_NULL
               else
                 Bubbletea::KeyMessage::KEY_RUNES
               end
    runes = key_type == Bubbletea::KeyMessage::KEY_RUNES ? name.chars.map(&:ord) : []
    Bubbletea::KeyMessage.new(key_type:, runes:, alt:, name:)
  end

  def resize(width, height)
    Bubbletea::WindowSizeMessage.new(width:, height:)
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

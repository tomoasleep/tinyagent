# frozen_string_literal: true

module Tinyagent
  class ThreadItem < Model
    plugin :class_table_inheritance, key: :type
    many_to_one :thread
  end
end

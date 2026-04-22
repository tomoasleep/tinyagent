# frozen_string_literal: true

module Tinyagent
  # Abstract item on thread
  class ThreadItem < Model
    plugin :class_table_inheritance, key: :type
  end
end

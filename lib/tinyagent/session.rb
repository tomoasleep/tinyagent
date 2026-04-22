# frozen_string_literal: true

module Tinyagent
  # Manage thread-specific data.
  class Session < Model
    one_to_one :threads, key: :thread_id
  end
end

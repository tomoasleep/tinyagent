# frozen_string_literal: true

module Tinyagent
  # Global settings for AI agent.
  class GlobalSettings
    attr_reader :database #: Tinyagent::Database

    NAMESPACE_KEYS = [:global_settings].freeze #: Array[Database::keynable]

    class << self
      def find_or_create(database:) #: GlobalSettings
        new(database: database)
      end
    end

    # @rbs database: Tinyagent::Database
    def initialize(database:)
      @database = database
    end

    def system_prompt #: String?
      database.fetch(*NAMESPACE_KEYS, :system_prompt)
    end

    # @rbs prompt: String?
    # @rbs return: void
    def system_prompt=(prompt)
      database.store(prompt, at: [*NAMESPACE_KEYS, :system_prompt])
    end
  end
end

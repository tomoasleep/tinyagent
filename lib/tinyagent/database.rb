# frozen_string_literal: true

module Tinyagent
    # Memorize and retrieve information using brain storage.
  class Database
    # @rbs!
    #   type keynable = String | Integer

    autoload :QueryMethods, 'tinyagent/database/query_methods'

    include QueryMethods

    NAMESPACE = :tinyagent

    attr_reader :brain #: _Brain

    # @rbs brain: _Brain
    def initialize(brain)
      @brain = brain
    end

    def data #: Hash[keynable, untyped]
      brain.data[NAMESPACE] ||= {} # steep:ignore UnannotatedEmptyCollection
    end

    def user(id) #: User
      User.find_or_create(database: self, id: id)
    end

    def chat_thread(id) #: ChatThread
      ChatThread.find_or_create(database: self, id: id)
    end

    # @rbs %a{memorized}
    def global_settings #: GlobalSettings
      @global_settings ||= GlobalSettings.find_or_create(database: self)
    end
  end
end

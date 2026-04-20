# frozen_string_literal: true

module DatabaseFactory
  include BrainFactory

  def create_database(data = {})
    brain = create_brain(data)
    Tinyagent::Database.new(brain)
  end
end

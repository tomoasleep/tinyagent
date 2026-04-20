# frozen_string_literal: true

module BrainFactory
  def create_brain(data = {})
    brain_data = { Tinyagent::Database::NAMESPACE => data }

    Struct.new(:data).new(brain_data)
  end
end

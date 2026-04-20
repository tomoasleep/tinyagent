# frozen_string_literal: true

module MessageFactory
  include BrainFactory

  FakeMessage = Struct.new(:body, :from, :from_name, :to, :original, :robot, keyword_init: true)
  FakeRobot = Struct.new(:brain, :name, keyword_init: true)

  def create_message(body:, from: 'user1', from_name: 'User1', to: 'bot', replies: [])
    brain = create_brain
    robot = FakeRobot.new(brain: brain, name: 'testbot')
    msg = FakeMessage.new(body: body, from: from, from_name: from_name, to: to, original: nil, robot: robot)

    msg.singleton_class.class_eval do
      define_method(:[]) { |key| to_h[key] }
      define_method(:to_h) { { body: body, from: from, to: to } }
      define_method(:reply) { |text| replies << text }
    end

    msg
  end
end

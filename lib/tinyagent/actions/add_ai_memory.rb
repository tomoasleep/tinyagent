# frozen_string_literal: true

module Tinyagent
  module Actions
    # AddAiMemory action for Tinyagent
    class AddAiMemory < Base
      def call
        idx = user.ai_memories.add(prompt_param)

        message.reply("Added memory #{idx}: #{prompt_param}")
      end

      def prompt_param #: String
        message[:prompt]
      end
    end
  end
end

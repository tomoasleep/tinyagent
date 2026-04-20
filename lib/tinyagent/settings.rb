# frozen_string_literal: true

module Tinyagent
  # Provide library-wide settings.
  class Settings
    # Provide access to settings instance.
    module Accessor
      def settings #: Tinyagent::Settings
        Settings.instance
      end
    end

    # @rbs %a{memorized}
    def self.instance #: Tinyagent::Settings
      @instance ||= Settings.new
    end

    def max_tokens #: Integer?
      ENV['AI_AGENT_MAX_TOKENS']&.to_i
    end

    def auto_compact_threshold #: Float
      ENV.fetch('AI_AGENT_AUTO_COMPACT_THRESHOLD', '80').to_f
    end
  end
end

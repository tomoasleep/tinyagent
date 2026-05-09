# frozen_string_literal: true

require 'lipgloss'
require 'bubbletea'

module Tinyagent
  module Tui
    class Chat
      # Renders status bar and help text.
      # Manages status state via Bubbletea::Model.
      class StatusBar
        include Bubbletea::Model

        # @rbs @status_message: String
        # @rbs @provider: String
        # @rbs @model: String
        # @rbs @token_usage: Tinyagent::TokenUsage?

        # Message sent to update the status message.
        class UpdateStatusMessage < Bubbletea::Message
          attr_reader :status_message #: String

          # @rbs status_message: String
          def initialize(status_message) #: void
            super()
            @status_message = status_message
          end
        end

        # Message sent to update model/provider info.
        class UpdateModelInfoMessage < Bubbletea::Message
          attr_reader :provider #: String
          attr_reader :model #: String

          # @rbs provider: String
          # @rbs model: String
          def initialize(provider, model) #: void
            super()
            @provider = provider
            @model = model
          end
        end

        # Message sent to update token usage.
        class UpdateTokenUsageMessage < Bubbletea::Message
          attr_reader :token_usage #: Tinyagent::TokenUsage?

          # @rbs token_usage: Tinyagent::TokenUsage?
          def initialize(token_usage) #: void
            super()
            @token_usage = token_usage
          end
        end

        def initialize #: void
          @status_message = ''
          @provider = ''
          @model = ''
          @token_usage = nil
        end

        def init #: Array[untyped]
          [self, nil]
        end

        # @rbs message: Bubbletea::Message
        def update(message) #: Array[untyped]
          case message
          when UpdateStatusMessage
            @status_message = message.status_message
          when UpdateModelInfoMessage
            @provider = message.provider
            @model = message.model
          when UpdateTokenUsageMessage
            @token_usage = message.token_usage
          end
          [self, nil]
        end

        def view #: String
          parts = [] #: Array[String]
          status_text = plain_status_text
          footer_text = plain_footer_text

          parts << status_text unless status_text.empty?
          parts << footer_text unless footer_text.empty?

          Lipgloss::Style.new.foreground('241').render(parts.join(' | '))
        end

        def status_view #: String
          Lipgloss::Style.new.foreground('241').render(plain_status_text)
        end

        def footer_view #: String
          Lipgloss::Style.new.foreground('241').render(plain_footer_text)
        end

        def help_text #: String
          <<~TEXT
            Welcome to tinyagent chat!

            Press Ctrl+P to open command palette
            Press Ctrl+C to quit
            Use /clear, /compact, /usage for commands
          TEXT
        end

        private

        def plain_status_text #: String
          parts = [] #: Array[String]
          token_usage = @token_usage
          parts << @status_message if @status_message && !@status_message.empty?
          parts << "tokens:#{token_usage.total_tokens}" if token_usage

          parts.join(' | ')
        end

        def plain_footer_text #: String
          "model:#{@provider}/#{@model}"
        end
      end
    end
  end
end

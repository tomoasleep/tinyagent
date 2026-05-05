# frozen_string_literal: true

module Tinyagent
  # Run the agent completion loop with configuration and persistence.
  class CompletionLoop
    attr_reader :thread #: Thread

    # @rbs thread: Thread
    # @rbs configuration: Configuration
    def initialize(thread:, configuration: nil) #: void
      @thread = thread
      @configuration = configuration
    end

    # @rbs @configuration: Configuration?
    # @rbs @llm: LLM::OpenAI

    def configuration #: Configuration
      @configuration ||= Configuration.new
    end

    def llm #: LLM::OpenAI
      @llm ||= build_llm
    end

    def build_llm #: LLM::OpenAI
      provider = build_provider(configuration.current_provider)
      LLM::OpenAI.new(
        client: provider.build_client,
        model: configuration.current_model
      )
    end

    # @rbs provider_id: Symbol
    def build_provider(provider_id) #: LLM::Provider
      catalog = ModelsDev::Catalog.new
      provider_data = catalog.openai_compatible_providers[provider_id.to_s]

      unless provider_data
        return LLM::Provider.new(
          id: provider_id,
          name: provider_id,
          base_url: ENV.fetch('OPENAI_BASE_URL', nil),
          api_key_env: 'OPENAI_API_KEY'
        )
      end

      config = configuration.provider_config(provider_id)
      LLM::Provider.new(
        id: provider_id,
        name: provider_data['name'],
        base_url: config['base_url'] || provider_data['api'],
        api_key: config['api_key'],
        api_key_env: provider_data['env']&.first
      )
    rescue StandardError
      LLM::Provider.new(
        id: provider_id,
        name: provider_id,
        base_url: ENV.fetch('OPENAI_BASE_URL', nil),
        api_key_env: 'OPENAI_API_KEY'
      )
    end

    def completion_loop #: void
      thread.refresh
      agent.complete do |event|
        case event[:type]
        when :new_message
          thread.add_message(
            role: event[:message].role,
            content: event[:message].content
          )
        when :tool_call
          # Tool calls are logged via events if needed
        when :tool_response
          msg = event[:message]
          thread.add_message(
            role: msg.role,
            content: msg.content
          )
          if msg.tool_calls.any?
            msg.tool_calls.each do |tc|
              Tinyagent::ToolCall.create(
                message_id: thread.messages.last.id,
                api_id: tc.api_id,
                name: tc.name,
                arguments: tc.arguments
              )
            end
          end
        end
      end

      thread.compact(llm:) if thread.over_auto_compact_threshold?
    rescue StandardError => e
      if ENV['DEBUG']
        warn e.full_message
      else
        warn e.message
      end
    end

    def agent #: Agent
      Agent.new(
        llm:,
        messages: thread.messages,
        tools:
      )
    end

    def tools #: Array[Tool]
      thread.tools
    end
  end
end

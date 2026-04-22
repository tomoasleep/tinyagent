# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:sessions) do
      primary_key :id

      foreign_key :thread_id, :threads
    end

    create_table(:threads) do
      primary_key :id
      foreign_key :session_id, :sessions
    end

    create_table(:thread_items) do
      primary_key :id
      foreign_key :thread_id, :threads

      String :type, null: false
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end

    create_table(:messages) do
      foreign_key :id, :thread_items, primary_key: true

      Integer :role_id, null: false
      String :content, text: true

      Integer :token_usage_prompt_tokens
      Integer :token_usage_completion_tokens
      Integer :token_usage_total_tokens
      Integer :token_usage_token_limit
    end

    create_table(:tool_calls) do
      primary_key :id
      foreign_key :message_id, :messages

      String :api_id, null: false
      String :name, null: false
      String :arguments, text: true
      String :response, text: true
    end
  end
end

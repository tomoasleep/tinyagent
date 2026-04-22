# frozen_string_literal: true

Sequel.migration do
  change do
    create_tables(:sessions) do
      primary_key :id

      foreign_key :thread_id, :threads
    end

    create_tables(:threads) do
      primary_key :id
      foreign_key :session_id, :sessions
    end

    create_tables(:thread_item) do
      primary_key :id
      foreign_key :thread_id, :threads

      String :type, null: false
      Datetime :created_at, null: false
    end

    create_tables(:messages) do
      primary_key :id

      Integer :role_id, null: false

      String :content
    end

    create_tables(:tool_call) do
      primary_key :id
      foreign_key :message_id, :messages

      String :name, null: false
      String :arguments, null: false
      String :response
    end

    create_tables(:tools) do
      primary_key :id

      String :name
    end
  end
end

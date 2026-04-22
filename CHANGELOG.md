## Unreleased

### Added

- Add interactive Chat TUI (`tinyagent tui`) built on Bubbletea Elm Architecture
- Add message history viewport with scrolling (j/k, PgUp/PgDn)
- Add text input mode (press `i` to enter, Escape to cancel, Enter to send)
- Add slash commands: `/clear`, `/compact`, `/usage`
- Add spinner animation during LLM completion
- Add token usage display in status bar

### Changed

- Replace custom Hash-based Database layer with Sequel ORM models
- Replace ChatMessage/ChatThread with Sequel-based Message/Thread models
- Use Class Table Inheritance for ThreadItem/Message hierarchy
- Store token usage directly in messages table columns
- Store tool call details via associated ToolCall records (api_id, name, arguments)
- Remove Recordable serialization system
- Remove Actions, Commands, User, GlobalSettings brain-based layers
- Remove Database, RecordSet, ChatThreadAssociations, UserAssociations

## Unreleased (previous)

### Changed

- Rename gem from `ruboty-ai_agent` to `tinyagent`
- Change namespace from `Ruboty::AiAgent` to `Tinyagent`
- Remove Ruboty dependency - now a standalone gem
- Change Database::NAMESPACE from `:ai_agent` to `:tinyagent`
- Move entry point from `lib/ruboty/ai_agent.rb` to `lib/tinyagent.rb`

## 0.4.0

- Add `bot_help` builtin tool to retrieve Ruboty's help information.
- Add `fetch` builtin tool for fetching web content.
- Fix `/usage` command to show token usage of last message.
- Format tool call logs for better readability.

## 0.3.0

- Add think tool.
- Different agent threads are prepared for different slack threads.

## 0.2.0

- Support for user defined commends.
- Agent uses user defined system prompts and memories.
- Support automatic prompt compaction.

## 0.1.0

- Initial release with basic features and functionality.

## Unreleased

### Changed

- Restore a separate chat footer layout: status messages render above the input, the input prompt keeps its vertical bar, and model info moves to the final line
- Remove input mode: text input is now always available in the chat TUI. Press Enter to send, Escape to clear input
- Remove `q` key quit; use Ctrl+C to quit
- Show status info (model, tokens, status messages) in the text input prompt instead of a separate status bar

### Changed

- Replace `Bubbles::TextInput` with `Bubbles::TextArea` in Chat TUI for multi-line input support
- Add sender color styling (purple for "You:", cyan for "Assistant:", yellow for tools) to chat messages in viewport
- Add word wrapping for chat messages based on viewport width
- Update Chat TUI layout to accommodate TextArea height in viewport calculation

### Changed

- Fix `Tui::Chat` palette state handling, message submission, and thread-backed status updates after the chat component split
- Move model change from Ctrl+M keybinding to Command Palette (`change model` command)
- E2E テストを `include` チェックから画面全体のスナップショット比較 (`match_screen`) に移行しました
- E2E テストの端末サイズを spec 毎に `screen_size` で設定可能にしました（デフォルト: 80x12）
- Resolve `Style/Documentation` offenses by adding doc comments to all public classes and modules
- Resolve RSpec/MultipleExpectations offenses by adding `aggregate_failures` to affected examples
- Resolve `Style/DisableCopsWithinSourceCodeDirective` offenses by removing inline disable directives and adding `super()` call
- Remove hand-written column accessor RBS definitions for Sequel models (now auto-generated)

### Added

- Add `UPDATE_SNAPSHOT` env var to auto-update `match_screen` heredoc snapshots after E2E test suite
- Add `script/generate-schema-model-rbs.rb` to auto-generate RBS type definitions for Sequel model columns and `initialize` from database schema
- Add `rake rbs:script` integration for the new schema model RBS generator

### Added

- Add `TinyAgent/DescriptionWording` custom RuboCop cop to disallow specific wording patterns in RSpec `context`, `describe`, and `it` descriptions

- Add models.dev integration: fetch OpenAI-compatible providers and available models on startup
- Add provider/model selection UI: press `Ctrl+M` to open a two-step picker (provider → model)
- Add `Tinyagent::Configuration` for persisting current provider/model and per-provider API keys in JSON files
- Add `Tinyagent::LLM::Provider` to abstract provider credentials and client building
- Add `Tinyagent::LLM::Model` to generalize model metadata (context limit, tool support)
- Add `Tinyagent::ModelsDev::Catalog` to fetch and cache the models.dev API catalog
- Add command palette with fuzzy search: press `Ctrl+P` to open a floating overlay with real-time filtering of commands (clear, compact, usage)
- Add `OPENAI_BASE_URL` environment variable support for custom LLM endpoints
- Add E2E test suite using AIMock and tuistory (`spec/e2e/`)
- Rewrite E2E tests from TypeScript/Vitest to Ruby/RSpec
- Allow Ctrl+C to quit the TUI from any state (input, thinking, idle)
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

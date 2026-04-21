# Tinyagent

A tiny AI agent framework with LLM integration, MCP (Model Context Protocol) support, and conversation management.

## Installation

Add to your Gemfile:

```ruby
gem 'tinyagent'
```

Then install:

```
bundle install
```

## Setup

### OpenAI

Configure environment variables (e.g., via `.env`):

- `OPENAI_API_KEY`: Your LLM provider API key (required)
- `OPENAI_MODEL`: Model name (optional)

## Usage

Tinyagent provides a framework for building AI agents with:

- LLM integration (currently OpenAI)
- MCP (Model Context Protocol) tool support
- Conversation tracking per thread
- Custom commands and memory management

### Basic Usage

```ruby
require 'tinyagent'

# Create a brain (storage)
brain = Struct.new(:data).new({ tinyagent: {} })

# Create a database
database = Tinyagent::Database.new(brain)

# Get or create a user
user = database.user('user_id')

# Get or create a chat thread
thread = database.chat_thread('thread_id')

# Add MCP configuration
user.mcp_configurations.add(Tinyagent::McpConfiguration.new(
  name: 'my_tool',
  transport: :http,
  url: 'https://example.com/mcp',
  headers: {}
))
```

### Actions

Actions are the main way to interact with the agent:

```ruby
# Chat action - processes a message through the LLM
Tinyagent::Actions::Chat.call(message)
```

### Available Tools

Built-in tools:
- `bot_help` - Show help information
- `fetch` - Fetch web page content
- `think` - Think through a problem step by step

### Commands

Conversation management:
- `clear` — Clear the current thread's conversation history
- `compact` — Summarize and compact the conversation history
- `usage` — Show token usage statistics

## Development

Install dependencies:

```
bin/setup
```

Run tests:

```
bundle exec rake spec
```

Interactive console:

```
bin/console
```

Install locally:

```
bundle exec rake install
```

Release:
Update `version.rb` and run `bundle exec rake release` to tag, push, and publish to RubyGems.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tomoasleep/tinyagent.

## Code of Conduct

Everyone interacting in the Tinyagent project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tomoasleep/tinyagent/blob/main/CODE_OF_CONDUCT.md).
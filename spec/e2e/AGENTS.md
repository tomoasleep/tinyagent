# E2E Test Guide

## Writing E2E tests with `match_screen`

E2E tests compare the full terminal screen snapshot against an expected screen.

### Basic flow

1. Define `screen_size` (optional, defaults to `{ cols: 120, rows: 36 }`)
2. Interact with the session (`press`, `type`, `wait_for_text`)
3. Assert the final screen with `match_screen`

### Workflow for writing a new test

1. Write the test with `match_screen('')` as a placeholder
2. Run the test — it will fail and print the **Actual screen** in the failure message
3. Copy the actual screen output into the `match_screen(<<~SCREEN)` heredoc
4. Re-run to confirm it passes

### Example

```ruby
RSpec.describe 'my feature', type: :e2e do
  let(:screen_size) { { cols: 80, rows: 12 } }

  it 'does something' do
    session.wait_for_text('Welcome to tinyagent chat!', timeout: 10)
    session.press('i')
    session.type('hello')
    session.press('enter')

    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
      You: hello
      Assistant: response text

      ───────────────────────────────────────────────────────────────────────────────
      tokens:0 | model:openai/gpt-5-nano
    SCREEN
  end
end
```

### Dynamic elements

`match_screen` normalizes dynamic values automatically:

- `model:<anything>` → `model:PROVIDER/MODEL`
- `tokens:<number>` → `tokens:N`

So you can write the literal values in the expected screen and they will be normalized on both sides.

### Updating snapshots

When the UI changes and snapshots need updating, run:

```bash
UPDATE_SNAPSHOT=1 bundle exec rspec spec/e2e/ --tag type:e2e
```

This will:
1. Run all E2E tests (always passing the `match_screen` assertions)
2. After the suite finishes, rewrite the heredoc content in each spec file with the actual screen output
3. Print a summary of updated snapshots

Review the changes with `git diff` before committing.

### Screen size

Use `let(:screen_size)` to set terminal dimensions per example group. Choose a size that fits the content without excessive blank lines:

```ruby
let(:screen_size) { { cols: 80, rows: 12 } }   # simple screens
let(:screen_size) { { cols: 80, rows: 14 } }   # overlays (palette, etc.)
```

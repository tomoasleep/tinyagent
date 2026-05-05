# frozen_string_literal: true

module ScreenMatching
  DYNAMIC_REPLACEMENTS = [
    [/model:\S+/, 'model:PROVIDER/MODEL'],
    [/tokens:\d+/, 'tokens:N']
  ].freeze

  def normalize_screen(text)
    result = text.strip
    DYNAMIC_REPLACEMENTS.each do |pattern, replacement|
      result = result.gsub(pattern, replacement)
    end
    result
  end

  RSpec::Matchers.define :match_screen do |expected|
    match do |actual|
      @actual_raw = actual
      @actual_normalized = normalize_screen(actual)
      @expected_normalized = normalize_screen(expected)
      @actual_normalized == @expected_normalized
    end

    failure_message do |_actual|
      <<~MSG
        Screen did not match.

        Actual screen:
        ─────────────────────────────────
        #{@actual_raw}
        ─────────────────────────────────

        Diff:
        #{RSpec::Support::Differ.new.diff_as_string(@actual_normalized, @expected_normalized)}
      MSG
    end
  end
end

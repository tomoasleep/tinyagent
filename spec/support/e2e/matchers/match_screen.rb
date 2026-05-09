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

  @snapshot_updates = []

  def self.snapshot_updates
    @snapshot_updates
  end

  def self.update_snapshots!
    updates_by_file = snapshot_updates.group_by { |u| u[:file] }

    updates_by_file.each do |file, updates|
      lines = File.readlines(file)

      updates.sort_by { |u| -u[:line] }.each do |update|
        line_idx = update[:line] - 1

        if lines[line_idx]&.match?(/match_screen\(<<~\w+\)/)
          replace_heredoc(lines, line_idx, update[:actual])
        elsif lines[line_idx]&.include?("match_screen('')")
          convert_empty_string_to_heredoc(lines, line_idx, update[:actual])
        end
      end

      File.write(file, lines.join)
    end
  end

  def self.replace_heredoc(lines, start_idx, content)
    first_content_idx = start_idx + 1
    indent = detect_indent(lines[first_content_idx])
    marker = lines[start_idx][/<<?~?(\w+)\)\s*$/, 1] || 'SCREEN'

    close_idx = find_close_marker(lines, first_content_idx, marker)
    return unless close_idx

    new_lines = content.lines.map { |l| l.chomp.empty? ? "\n" : "#{indent}#{l.chomp}\n" }
    lines[first_content_idx..(close_idx - 1)] = new_lines
  end

  def self.convert_empty_string_to_heredoc(lines, start_idx, content)
    base_indent = detect_indent(lines[start_idx])
    content_indent = "#{base_indent}  "

    lines[start_idx].sub!("match_screen('')", 'match_screen(<<~SCREEN)')

    new_lines = content.lines.map { |l| l.chomp.empty? ? "\n" : "#{content_indent}#{l.chomp}\n" }
    new_lines << "#{base_indent}SCREEN\n"
    lines.insert(start_idx + 1, *new_lines)
  end

  def self.detect_indent(line)
    line ? line.match(/^(\s*)/)[1] : ''
  end

  def self.find_close_marker(lines, from_idx, marker)
    (from_idx...lines.length).find { |i| lines[i].strip == marker }
  end

  RSpec::Matchers.define :match_screen do |expected|
    match do |actual|
      @actual_raw = actual
      @actual_normalized = normalize_screen(actual)
      @expected_normalized = normalize_screen(expected)

      if ENV['UPDATE_SNAPSHOT']
        location = caller_locations.find { |l| l.absolute_path&.include?('/spec/') }
        if location && @actual_normalized != @expected_normalized
          ScreenMatching.snapshot_updates << {
            file: location.absolute_path,
            line: location.lineno,
            actual: @actual_raw
          }
        end
        true
      else
        @actual_normalized == @expected_normalized
      end
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

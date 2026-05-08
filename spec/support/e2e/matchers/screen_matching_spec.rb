# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative 'match_screen'

RSpec.describe ScreenMatching do
  include described_class

  describe '#normalize_screen' do
    it 'strips whitespace' do
      expect(normalize_screen("  hello\n")).to eq('hello')
    end

    it 'replaces model names' do
      expect(normalize_screen('model:openai/gpt-5-nano')).to eq('model:PROVIDER/MODEL')
    end

    it 'replaces token counts' do
      expect(normalize_screen('tokens:42')).to eq('tokens:N')
    end
  end

  describe 'match_screen matcher' do
    it 'passes when screens match', :aggregate_failures do
      actual = "hello\nworld"
      expected = "hello\nworld"
      expect(actual).to match_screen(expected)
    end

    it 'fails when screens differ' do
      actual = 'hello'
      expected = 'different'
      expect { expect(actual).not_to match_screen(expected) }.not_to raise_error
    end

    context 'when UPDATE_SNAPSHOT is set' do
      around do |ex|
        original = ENV.fetch('UPDATE_SNAPSHOT', nil)
        ENV['UPDATE_SNAPSHOT'] = '1'
        described_class.snapshot_updates.clear
        ex.run
        ENV['UPDATE_SNAPSHOT'] = original ? '1' : nil
        described_class.snapshot_updates.clear
      end

      it 'always passes' do
        actual = 'anything'
        expected = 'different'
        expect(actual).to match_screen(expected)
      end

      it 'records snapshot update data', :aggregate_failures do
        actual = 'actual screen content'
        expected = 'expected'
        expect(actual).to match_screen(expected)
        expect(described_class.snapshot_updates.length).to be >= 1
        update = described_class.snapshot_updates.last
        expect(update[:actual]).to eq('actual screen content')
        expect(update[:file]).to include('screen_matching_spec.rb')
        expect(update[:line]).to be_a(Integer)
      end
    end
  end

  describe '.update_snapshots!' do
    let(:tmpdir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(tmpdir)
    end

    def write_spec_file(content)
      path = File.join(tmpdir, 'test_spec.rb')
      File.write(path, content)
      path
    end

    it 'replaces heredoc content with actual value', :aggregate_failures do
      source = <<~RUBY
        expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
          old content
          line 2
        SCREEN
      RUBY
      path = write_spec_file(source)

      described_class.snapshot_updates.clear
      described_class.snapshot_updates << {
        file: path,
        line: 1,
        actual: "new content\nupdated line"
      }

      described_class.update_snapshots!

      updated = File.read(path)
      expect(updated).to include('new content')
      expect(updated).to include('updated line')
      expect(updated).not_to include('old content')
    end

    it 'handles multiple updates in the same file in reverse line order', :aggregate_failures do
      source = <<~RUBY
        expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
          first old
        SCREEN
        some_other_line
        expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
          second old
        SCREEN
      RUBY
      path = write_spec_file(source)

      described_class.snapshot_updates.clear
      described_class.snapshot_updates << {
        file: path,
        line: 1,
        actual: 'first new'
      }
      described_class.snapshot_updates << {
        file: path,
        line: 5,
        actual: 'second new'
      }

      described_class.update_snapshots!

      updated = File.read(path)
      expect(updated).to include('first new')
      expect(updated).to include('second new')
      expect(updated).not_to include('first old')
      expect(updated).not_to include('second old')
      expect(updated).to include('some_other_line')
    end

    it 'preserves indentation of existing heredoc content' do
      source = "    expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)\n      old content\n    SCREEN\n"
      path = write_spec_file(source)

      described_class.snapshot_updates.clear
      described_class.snapshot_updates << {
        file: path,
        line: 1,
        actual: 'new content'
      }

      described_class.update_snapshots!

      updated = File.read(path)
      expect(updated).to include('    new content')
    end

    it 'converts empty string match_screen to heredoc', :aggregate_failures do
      source = "    expect(session.snapshot(trim: true)).to match_screen('')\n"
      path = write_spec_file(source)

      described_class.snapshot_updates.clear
      described_class.snapshot_updates << {
        file: path,
        line: 1,
        actual: 'converted content'
      }

      described_class.update_snapshots!

      updated = File.read(path)
      expect(updated).to include('match_screen(<<~SCREEN)')
      expect(updated).to include('converted content')
      expect(updated).not_to include("match_screen('')")
    end

    it 'does not leave trailing spaces on blank lines in heredoc', :aggregate_failures do
      source = <<~RUBY
        expect(session.snapshot(trim: true)).to match_screen(<<~SCREEN)
          old content
        SCREEN
      RUBY
      path = write_spec_file(source)

      described_class.snapshot_updates.clear
      described_class.snapshot_updates << {
        file: path,
        line: 1,
        actual: "line 1\n\nline 3"
      }

      described_class.update_snapshots!

      updated = File.read(path)
      updated_lines = updated.lines
      blank_line = updated_lines.find { |l| l.strip.empty? }
      expect(blank_line).to eq("\n")
    end
  end
end

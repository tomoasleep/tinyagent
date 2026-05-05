# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../lib/rubocop/cop/tinyagent/description_wording'

RSpec.describe RuboCop::Cop::TinyAgent::DescriptionWording, :config do
  let(:config) do
    RuboCop::Config.new(
      'TinyAgent/DescriptionWording' => {
        'DisallowedPatterns' => disallowed_patterns
      }
    )
  end

  let(:disallowed_patterns) { [/should\b/] }

  context 'when DisallowedPatterns is empty' do
    let(:disallowed_patterns) { [] }

    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        context 'when something happens' do
          it 'should work' do
          end
        end
      RUBY
    end
  end

  it 'registers offense when context description matches a disallowed pattern' do
    expect_offense(<<~RUBY)
      context 'should do something' do
              ^^^^^^^^^^^^^^^^^^^^^ 'should\\b' is disallowed in context description.
        it 'does something' do
        end
      end
    RUBY
  end

  it 'registers offense when describe description matches a disallowed pattern' do
    expect_offense(<<~RUBY)
      describe 'should do something' do
               ^^^^^^^^^^^^^^^^^^^^^ 'should\\b' is disallowed in describe description.
        it 'does something' do
        end
      end
    RUBY
  end

  it 'registers offense when it description matches a disallowed pattern' do
    expect_offense(<<~RUBY)
      it 'should do something' do
         ^^^^^^^^^^^^^^^^^^^^^ 'should\\b' is disallowed in it description.
      end
    RUBY
  end

  it 'registers no offense when description does not match any pattern' do
    expect_no_offenses(<<~RUBY)
      context 'when something happens' do
        it 'does something' do
        end
      end
    RUBY
  end

  it 'handles xcontext' do
    expect_offense(<<~RUBY)
      xcontext 'should be skipped' do
               ^^^^^^^^^^^^^^^^^^^ 'should\\b' is disallowed in xcontext description.
      end
    RUBY
  end

  it 'handles xdescribe' do
    expect_offense(<<~RUBY)
      xdescribe 'should be skipped' do
                ^^^^^^^^^^^^^^^^^^^ 'should\\b' is disallowed in xdescribe description.
      end
    RUBY
  end

  it 'handles xit' do
    expect_offense(<<~RUBY)
      xit 'should work' do
          ^^^^^^^^^^^^^ 'should\\b' is disallowed in xit description.
      end
    RUBY
  end

  context 'with a string pattern' do
    let(:disallowed_patterns) { ['works'] }

    it 'registers offense when description contains the disallowed string' do
      expect_offense(<<~RUBY)
        it 'works correctly' do
           ^^^^^^^^^^^^^^^^^ 'works' is disallowed in it description.
        end
      RUBY
    end
  end
end

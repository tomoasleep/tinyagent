# frozen_string_literal: true

module RuboCop
  module Cop
    module TinyAgent
      # Checks for disallowed wording patterns in RSpec context, describe, and it descriptions.
      class DescriptionWording < ::RuboCop::Cop::Base
        MSG = "'%<pattern>s' is disallowed in %<method>s description."

        METHODS = %i[context describe it xcontext xdescribe xit].freeze

        def_node_matcher :rspec_description, <<~PATTERN
          (block (send {nil? (const _ :RSpec)} {:context :describe :it :xcontext :xdescribe :xit} $({str dstr xstr} ...) ...) ...)
        PATTERN

        def on_block(node)
          rspec_description(node) do |description_node|
            check_description(node, description_node)
          end
        end

        private

        def check_description(block_node, description_node)
          description = text(description_node)
          method_name = block_node.children[0].method_name

          disallowed_patterns.each do |pattern|
            next unless description.match?(pattern)

            add_offense(
              description_node,
              message: format(MSG, pattern: pattern_source(pattern), method: method_name)
            )
          end
        end

        def text(node)
          case node.type
          when :dstr
            node.node_parts.map { |child| child.is_a?(String) ? child : child.source }.join
          when :xstr
            node.value.value
          else
            node.value
          end
        end

        def disallowed_patterns
          patterns = cop_config.fetch('DisallowedPatterns', [])
          patterns.map { |p| p.is_a?(Regexp) ? p : Regexp.new(p) }
        end

        def pattern_source(pattern)
          pattern.is_a?(Regexp) ? pattern.source : pattern
        end
      end
    end
  end
end

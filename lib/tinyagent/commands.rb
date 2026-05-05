# frozen_string_literal: true

module Tinyagent
  # Interaction commands (a.k.a. Slash commands, Prompts, etc)
  module Commands
    autoload :Base, 'tinyagent/commands/base'
    autoload :BuiltinBase, 'tinyagent/commands/builtin_base'
    autoload :Clear, 'tinyagent/commands/clear'
    autoload :Compact, 'tinyagent/commands/compact'
    autoload :Usage, 'tinyagent/commands/usage'
    autoload :PromptCommand, 'tinyagent/commands/prompt_command'

    # @rbs request: untyped
    def self.builtins(request:) #: Array[untyped]
      [
        Commands::Clear,
        Commands::Compact,
        Commands::Usage
      ].map { |cmd_class| cmd_class.new(request:) }
    end
  end
end

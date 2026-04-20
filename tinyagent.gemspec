# frozen_string_literal: true

require_relative 'lib/tinyagent/version'

Gem::Specification.new do |spec|
  spec.name = 'tinyagent'
  spec.version = Tinyagent::VERSION
  spec.authors = ['Tomoya Chiba']
  spec.email = ['tomo.asleep@gmail.com']

  spec.summary = 'A tiny AI agent framework.'
  spec.description = 'A tiny AI agent framework with LLM integration, MCP support, and conversation management.'
  spec.homepage = 'https://github.com/tomoasleep/tinyagent'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => 'https://github.com/tomoasleep/tinyagent',
    'changelog_uri' => 'https://github.com/tomoasleep/tinyagent/blob/main/CHANGELOG.md',
    'rubygems_mfa_required' => 'true',
    'allowed_push_host' => 'https://rubygems.org'
  }

  spec.files = Dir.glob('{lib,script}/**/*', File::FNM_DOTMATCH).reject { |f| f.end_with?('.gitkeep') }
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'event_stream_parser', '~> 1.0'
  spec.add_dependency 'openai', '~> 0.22.0'
end

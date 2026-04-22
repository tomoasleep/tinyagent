# frozen_string_literal: true

require 'rbs'
require 'pathname'

# Load RBS environment
loader = RBS::EnvironmentLoader.new
loader.add(path: Pathname('sig'))
loader.add(path: Pathname('.gem_rbs_collection'))
environment = RBS::Environment.from_loader(loader).resolve_type_names

*type_namespaces, type_name = ARGV[0].split('::').reject(&:empty?).map(&:to_sym)
namespace = RBS::Namespace.new(path: type_namespaces, absolute: true)
typename = RBS::TypeName.new(name: type_name, namespace: namespace)

decl = environment.class_decls[typename]

if decl.nil?
  puts "Type not found: #{typename}"
  exit 1
end

puts "Ancestors of #{typename}:"
puts

builder = RBS::DefinitionBuilder.new(env: environment)
definition = builder.build_instance(typename)

definition.ancestors.ancestors.each do |ancestor|
  puts "  #{ancestor.name}"
end

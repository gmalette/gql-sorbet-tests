require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "graphql/rake_task"
require "blog/gql/sorbet"

RSpec::Core::RakeTask.new(:spec)
GraphQL::RakeTask.new(schema_name: "Api::Schema")

task :default => :spec

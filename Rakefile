# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

Rake::Task["release:rubygem_push"].clear
desc "Pick up the .gem file from pkg/ and push it to Gemfury"
task "release:rubygem_push" do
  # IMPORTANT: You need to have the `fury` gem installed, and you need to be logged in.
  # Please DO READ about "impersonation", which is how you push to your company account instead
  # of your personal account!
  # https://gemfury.com/help/collaboration#impersonation
  paths = Dir.glob("#{__dir__}/pkg/*.gem")
  raise "Must have found only 1 .gem path, but found #{paths.inspect}" if paths.length != 1

  escaped_gem_path = Shellwords.escape(paths.shift)
  `fury push #{escaped_gem_path} --as=wetransfer`
end

namespace :db do
  require_relative "./spec/support/test_database"
  require "active_record"
  require "dotenv/load"
  Dotenv.load

  desc "Create databases to be used in tests"
  task "create" do
    adapter = ENV.fetch("ADAPTER", "mysql2")
    puts "Creating #{adapter}"
    TestDatabase.set_env_database_url(adapter)
    TestDatabase.establish_connection
    ActiveRecord::Base.connection.create_database(TestDatabase.database_name)
  end

  desc "Drop databases to be used in tests"
  task "drop" do
    adapter = ENV.fetch("ADAPTER", "mysql2")
    puts "Dropping #{adapter}"
    TestDatabase.set_env_database_url(adapter)
    TestDatabase.establish_connection
    ActiveRecord::Base.connection.drop_database(TestDatabase.database_name)
  end

  desc "Migrate databases to be used in tests"
  task "migrate" do
    adapter = ENV.fetch("ADAPTER", "mysql2")
    puts "Migrating #{adapter}"
    TestDatabase.set_env_database_url(adapter, with_database_name: true)
    TestDatabase.establish_connection
    TestDatabase.run_migrations
  end
end

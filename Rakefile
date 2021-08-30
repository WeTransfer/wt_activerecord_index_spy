# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

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

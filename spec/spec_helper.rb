# frozen_string_literal: true

require "dotenv/load"
Dotenv.load

ENV["RAILS_ENV"] = "test"

require "wt_activerecord_index_spy"
require "active_record"
require_relative "./support/test_database"

if ENV["LOG_QUERIES"]
  ActiveRecord::Base.logger = Logger.new($stdout)
  ActiveRecord::Base.logger.level = 0
end

if ENV["DEBUG"]
  WtActiverecordIndexSpy.logger = Logger.new($stdout)
  WtActiverecordIndexSpy.logger.level = 0
end

adapter = ENV.fetch("ADAPTER", "mysql2")

db_configs = TestDatabase.configs.find { |confs| confs[:adapter] == adapter }
ActiveRecord::Base.configurations = { test: db_configs }
ActiveRecord::Base.establish_connection

require_relative "./support/models"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Some tests may run only for a specific adapter, so we need to filter them
  all_adapters = TestDatabase.configs.map { |db_config| db_config[:adapter] }
  other_adapters = all_adapters - [adapter]
  other_adapters.each do |other_adapter|
    config.filter_run_excluding(only: other_adapter.to_sym)
  end

  config.around :each do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  config.expect_with :rspec do |c|
    c.max_formatted_output_length = 10_000
  end
end

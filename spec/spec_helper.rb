# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
require "dotenv/load"
Dotenv.load

ENV['RAILS_ENV'] = 'test'

require "wt_activerecord_index_spy"
require "active_record"
require_relative "./support/test_database"

require 'database_cleaner/active_record'
DatabaseCleaner.strategy = :truncation

if ENV['LOG_QUERIES']
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = 0
end
# WtActiverecordIndexSpy.logger = Logger.new(STDOUT)
# WtActiverecordIndexSpy.logger.level = 0

adapter = ENV.fetch('ADAPTER', 'mysql2')

db_configs = TestDatabase.configs.find{ |confs| confs[:adapter] == adapter }
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

  config.after :each do
    DatabaseCleaner.clean
  end

  config.expect_with :rspec do |c|
    c.max_formatted_output_length = 10_000
  end
end
# rubocop:enable Metrics/MethodLength

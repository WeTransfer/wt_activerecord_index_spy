# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
require "dotenv/load"
Dotenv.load

require "wt_activerecord_index_spy"
require "active_record"
require_relative "./support/test_database"

# ActiveRecord::Base.logger = Logger.new(STDOUT)
# ActiveRecord::Base.logger.level = 0
# WtActiverecordIndexSpy.logger = Logger.new(STDOUT)
# WtActiverecordIndexSpy.logger.level = 0

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before :all do
    ActiveRecord::Base.establish_connection(TestDatabase.configs[:mysql])
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

class User < ActiveRecord::Base
  def self.some_method_with_a_query_missing_index
    find_by(name: "any")
  end
end

class City < ActiveRecord::Base;
end
# rubocop:enable Metrics/MethodLength

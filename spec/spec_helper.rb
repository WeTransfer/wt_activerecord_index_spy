# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
require "dotenv/load"
Dotenv.load

require "wt_activerecord_index_spy"
require "active_record"

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
    db_configs = {
      mysql: {
        adapter: "mysql2",
        host: ENV.fetch("MYSQL_DB_HOST", "localhost"),
        username: ENV.fetch("MYSQL_DB_USER", "root"),
        password: ENV.fetch("MYSQL_DB_PASSWORD", "root"),
        database: "wt_activerecord_index_spy_test"
      }
    }

    # TODO: the must be a better way to create and connect to the database
    db_configs.each do |adapter, db_config|
      ActiveRecord::Base.establish_connection(db_config.reject { |k, _v| k == :database })
      ActiveRecord::Base.connection.create_database(db_config[:database])
      ActiveRecord::Base.establish_connection(db_config)

      run_migrations
    end
  end

  config.around :each do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  config.after :all do
    ActiveRecord::Base.connection.drop_database("wt_activerecord_index_spy_test")
  end

  config.expect_with :rspec do |c|
    c.max_formatted_output_length = 10_000
  end
end

def run_migrations
  create_table_migration = Class.new(ActiveRecord::Migration[6.0]) do
    def change
      create_table :users do |t|
        t.string :name
        t.string :email
        t.integer :age
        t.integer :city_id
      end

      add_index :users, :email
      add_index :users, :city_id

      create_table :cities do |t|
        t.string :name
      end
    end
  end

  create_table_migration.new.change
end

class User < ActiveRecord::Base
  def self.some_method_with_a_query_missing_index
    find_by(name: "any")
  end
end

class City < ActiveRecord::Base; end
# rubocop:enable Metrics/MethodLength

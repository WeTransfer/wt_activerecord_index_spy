# frozen_string_literal: true

require "dotenv/load"
Dotenv.load

require "mysql_index_checker"
require "active_record"

# ActiveRecord::Base.logger = Logger.new(STDOUT)
# ActiveRecord::Base.logger.level = 0

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before :all do
    db_config = {
      adapter: "mysql2",
      host: "localhost",
      username: ENV.fetch("DB_USER", "root"),
      password: ENV.fetch("DB_PASSWORD", "root"),
      database: "mysql_index_checker_test"
    }
    # TODO: the must be a better way to create and connect to the database
    ActiveRecord::Base.establish_connection(db_config.reject { |k, _v| k == :database })
    ActiveRecord::Base.connection.create_database(db_config[:database])
    ActiveRecord::Base.establish_connection(db_config)

    create_table_migration = Class.new(ActiveRecord::Migration[6.0]) do
      def change
        create_table :users do |t|
          t.string :name
          t.string :email
          t.integer :age
        end

        add_index :users, :email
      end
    end

    create_table_migration.new.change
  end

  config.around :each do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  config.after :all do
    ActiveRecord::Base.connection.drop_database("mysql_index_checker_test")
  end
end

class User < ActiveRecord::Base; end

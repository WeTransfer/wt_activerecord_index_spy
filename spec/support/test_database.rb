# typed: false
# frozen_string_literal: true

module TestDatabase
  extend self

  def adapters
    %w[mysql2 postgresql]
  end

  def database_name
    ENV.fetch("DATABASE_NAME", "wt_activerecord_index_spy_test")
  end

  def set_env_database_url(adapter, with_database_name: false)
    ENV["DATABASE_URL"] = ENV.fetch("DATABASE_URL_#{adapter.upcase}")

    ENV["DATABASE_URL"] += "/#{database_name}" if with_database_name
  end

  def establish_connection
    ActiveRecord::Base.establish_connection(ENV.fetch("DATABASE_URL"))
  end

  def run_migrations
    create_table_migration = Class.new(migration_class) do
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

  private

  def migration_class
    if ActiveRecord.version > Gem::Version.new("5.0.0")
      ActiveRecord::Migration[4.2]
    else
      ActiveRecord::Migration
    end
  end
end

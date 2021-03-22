module TestDatabase
  extend self

  def configs
    {
      mysql: {
        adapter: "mysql2",
        host: ENV.fetch("MYSQL_DB_HOST", "localhost"),
        username: ENV.fetch("MYSQL_DB_USER", "root"),
        password: ENV.fetch("MYSQL_DB_PASSWORD", ""),
        database: "wt_activerecord_index_spy_test"
      },
      postgresql: {
        adapter: "postgresql",
        host: ENV.fetch("POSTGRES_DB_HOST", "localhost"),
        username: ENV.fetch("POSTGRES_DB_USER", "postgres"),
        password: ENV.fetch("POSTGRES_DB_PASSWORD", ""),
        database: "wt_activerecord_index_spy_test"
      }
    }
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
end

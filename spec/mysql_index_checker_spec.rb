# frozen_string_literal: true

RSpec.describe MysqlIndexChecker do
  it "has a version number" do
    expect(MysqlIndexChecker::VERSION).not_to be nil
  end

  before :all do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = 0

    ActiveRecord::Base.establish_connection(
      adapter:  'mysql2',
      host:     'localhost',
      username: ENV.fetch('DB_USER', 'root'),
      password: ENV.fetch('DB_PASSWORD', '')
    )

    ActiveRecord::Base.connection.create_database('mysql_index_checker_test')

    ActiveRecord::Base.establish_connection(
      adapter:  'mysql2',
      host:     'localhost',
      username: ENV.fetch('DB_USER', 'root'),
      password: ENV.fetch('DB_PASSWORD', ''),
      database: 'mysql_index_checker_test'
    )

    migration = Class.new(ActiveRecord::Migration[6.0]) do
      def change
        create_table :users do |t|
          t.string  :name
        end
      end
    end

    migration.new.change

    class User < ActiveRecord::Base; end
  end

  after :all do
    ActiveRecord::Base.connection.drop_database('mysql_index_checker_test')
  end

  it "does something useful" do
    User.create!(name: 'lala')

    expect(User.where(name: 'lala').count).to eq(1)
  end
end

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
    # TODO: use database cleaner
    ActiveRecord::Base.connection.drop_database('mysql_index_checker_test')
  end

  describe '.raise_error_when_a_query_does_not_use_an_index' do
    context 'when a query does not use an index' do
      it "raises QueryNotUsingIndex " do
        User.create!(name: 'lala')

        expect do
          described_class.raise_error_when_a_query_does_not_use_an_index do
            User.find_by(name: 'lala')
          end
        end.to raise_error(described_class::QueryNotUsingIndex)
      end
    end

    context 'when a query uses an index' do
      it "does not raise QueryNotUsingIndex " do
        User.create!(name: 'lala', id: 1)

        expect do
          described_class.raise_error_when_a_query_does_not_use_an_index do
            User.find_by(id: 1)
          end
        end.not_to raise_error(described_class::QueryNotUsingIndex)
      end
    end
  end
end

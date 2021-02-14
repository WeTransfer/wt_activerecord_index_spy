# frozen_string_literal: true

RSpec.describe MysqlIndexChecker do
  it "has a version number" do
    expect(MysqlIndexChecker::VERSION).not_to be nil
  end

  before :each do
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
          t.string :email
        end

        add_index :users, :email
      end
    end

    migration.new.change

    class User < ActiveRecord::Base; end
  end

  after :each do
    ActiveRecord::Base.connection.drop_database('mysql_index_checker_test')
  end

  describe '.check_and_raise_error' do
    context 'when a query does not use an index' do
      it "raises QueryNotUsingIndex " do
        begin
          described_class.check_and_raise_error do
            User.find_by(name: 'lala')
          end

          raise 'this test should have raised an error'
        rescue described_class::QueryNotUsingIndex => e
          expect(e.message).to include("WHERE `users`.`name` = 'lala'")
        end
      end
    end

    context 'when a query uses the primary key index' do
      it "does not raise QueryNotUsingIndex " do
        expect do
          described_class.check_and_raise_error do
            User.find_by(id: 1)
          end
        end.not_to raise_error
      end
    end

    context 'when a query uses some index' do
      it "does not raise QueryNotUsingIndex " do
        expect do
          described_class.check_and_raise_error do
            User.find_by(email: 'aa@aa.com')
          end
        end.not_to raise_error
      end
    end
  end
end

# typed: false
# frozen_string_literal: true

RSpec.describe WtActiverecordIndexSpy::NotificationListener do
  let(:aggregator) { WtActiverecordIndexSpy::Aggregator.new }
  let(:query) { "SELECT * from users where name like 'lala%'" }

  it "ignores queries to INFORMATION_SCHEMA", only: [:mysql2] do
    WtActiverecordIndexSpy.watch_queries(aggregator: aggregator, ignore_queries_originated_in_test_code: false) do
      ActiveRecord::Base.connection.execute(
        "SELECT count FROM INFORMATION_SCHEMA.INNODB_METRICS "\
        "WHERE name='log_lsn_checkpoint_age'"
      )
    end

    expect(aggregator.certain_results.count).to eq(0)
    expect(aggregator.uncertain_results.count).to eq(0)
  end

  describe "Identifier not provided by ActiveRecord" do
    let(:values) do
      { sql: query }
    end

    before(:each) do
      listener = WtActiverecordIndexSpy::NotificationListener.new(ignore_queries_originated_in_test_code: false,
                                                                  aggregator: aggregator)
      listener.call("name", "start", "finish", "message_id", values)
    end

    it "defaults to empty string if identifier not provided (mysql)", only: [:mysql2] do
      expect(aggregator.uncertain_results.count).to eq 0
      expect(aggregator.certain_results.count).to eq 1
      expect(aggregator.certain_results.first.identifier).to eq ""
    end

    it "defaults to empty string (postgresql)", only: [:postgresql] do
      expect(aggregator.certain_results.count).to eq 0
      expect(aggregator.uncertain_results.count).to eq 1
      expect(aggregator.uncertain_results.first.identifier).to eq ""
    end
  end

  context "when the adapter is mysql2" do
    it "does not ignore queries with empty identifier", only: [:mysql2] do
      User.create!(name: "lala")
      WtActiverecordIndexSpy.watch_queries(aggregator: aggregator, ignore_queries_originated_in_test_code: false) do
        ActiveRecord::Base.connection.execute(query)
      end

      expect(aggregator.certain_results.count).to eq(1)
      expect(aggregator.uncertain_results.count).to eq(0)
    end
  end

  context "when the adapter is postgresql" do
    it "does not ignore queries with empty identifier", only: [:postgresql] do
      User.create!(name: "lala")

      WtActiverecordIndexSpy.watch_queries(aggregator: aggregator, ignore_queries_originated_in_test_code: false) do
        ActiveRecord::Base.connection.execute(query)
      end

      expect(aggregator.certain_results.count).to eq(0)
      expect(aggregator.uncertain_results.count).to eq(1)
    end
  end
end

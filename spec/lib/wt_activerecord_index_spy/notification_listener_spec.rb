RSpec.describe WtActiverecordIndexSpy::NotificationListener do
  it 'ignores queries to INFORMATION_SCHEMA', only: [:mysql2] do
    aggregator = WtActiverecordIndexSpy::Aggregator.new

    WtActiverecordIndexSpy.watch_queries(aggregator: aggregator, ignore_queries_originated_in_test_code: false) do
      ActiveRecord::Base.connection.query("SELECT count FROM INFORMATION_SCHEMA.INNODB_METRICS WHERE name='log_lsn_checkpoint_age'")
    end

    expect(aggregator.certain_results.count).to eq(0)
    expect(aggregator.uncertain_results.count).to eq(0)
  end

  it 'does not ignore queries with empty identifier' do
    aggregator = WtActiverecordIndexSpy::Aggregator.new
    User.create!(name: 'lala')

    WtActiverecordIndexSpy.watch_queries(aggregator: aggregator, ignore_queries_originated_in_test_code: false) do
      ActiveRecord::Base.connection.query(
        "SELECT * from users where name like 'lala%'"
      )
    end

    expect(aggregator.certain_results.count).to eq(1)
    expect(aggregator.uncertain_results.count).to eq(0)
  end
end

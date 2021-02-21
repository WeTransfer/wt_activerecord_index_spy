RSpec.describe MysqlIndexChecker::Aggregator do
  describe '#add_critical' do
    it 'saves unique queries to result' do
      aggregator = described_class.new

      (1..10).each do |index|
        query = "SELECT * FROM lala WHERE id = #{index}"
        aggregator.add_critical(identifier: 'any', query: query)
      end

      (1..10).each do |index|
        query = "SELECT * FROM lala WHERE id = #{index}"
        aggregator.add_critical(identifier: 'any', query: query)
      end

      expect(aggregator.results.criticals['any']).to be_a(Set)
      expect(aggregator.results.criticals['any'].size).to eq(10)
    end
  end
end

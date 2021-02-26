require 'tempfile'

RSpec.describe WtActiverecordIndexSpy::Aggregator do
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

  describe '#export_html_results' do
    it 'returns an html with results' do
      aggregator = described_class.new
      aggregator.add_critical(identifier: 'aa', query: 'SELECT 1')
      aggregator.add_critical(identifier: 'aa', query: 'SELECT 2')
      aggregator.add_critical(identifier: 'bb', query: 'SELECT 1')
      aggregator.add_warning(identifier: 'aa', query: 'SELECT 1')

      file = Tempfile.new
      stdout_spy = spy
      html = aggregator.export_html_results(file, stdout: stdout_spy)
      file.open
      file.rewind
      html = file.read

      expect(html).to match(%r|<td>critical</td>\n.+<td>aa</td>\n.+<td>SELECT 1</td>|)
      expect(html).to match(%r|<td>critical</td>\n.+<td>aa</td>\n.+<td>SELECT 2</td>|)
      expect(html).to match(%r|<td>critical</td>\n.+<td>bb</td>\n.+<td>SELECT 1</td>|)
      expect(html).to match(%r|<td>warning</td>\n.+<td>aa</td>\n.+<td>SELECT 1</td>|)

      expect(stdout_spy).to have_received(:puts).with(/Report exported to/)
    end
  end
end

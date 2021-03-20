# frozen_string_literal: true

require "tempfile"

module WtActiverecordIndexSpy
  RSpec.describe Aggregator do
    def build_item(**args)
      Aggregator::Item.new(args)
    end

    describe "#add_certain" do
      it "saves unique queries to result" do
        aggregator = described_class.new

        (1..10).each do |index|
          query = "SELECT * FROM lala WHERE id = #{index}"
          aggregator.add(build_item(identifier: "any", query: query), :certain)
          aggregator.add(build_item(identifier: "any", query: query), :certain)
        end

        expect(aggregator.results.certains.count).to eq(10)
      end
    end

    describe "#export_html_results" do
      it "returns an html with results" do
        aggregator = described_class.new
        aggregator.add(build_item(identifier: "aa", query: "SELECT 1", origin: "lala.rb"), :certain)
        aggregator.add(build_item(identifier: "aa", query: "SELECT 2", origin: "lala.rb"), :certain)
        aggregator.add(build_item(identifier: "bb", query: "SELECT 1", origin: "popo.rb"), :certain)
        aggregator.add(build_item(identifier: "aa", query: "SELECT 1", origin: "popo.rb"), :uncertain)

        file = Tempfile.new
        stdout_spy = spy
        aggregator.export_html_results(file, stdout: stdout_spy)
        file.open
        file.rewind
        html = file.read

        expect(html).to match(%r{<td>certain</td>\n.+<td>aa</td>\n.+<td>SELECT 1</td>\n.+<td>lala.rb</td>})
        expect(html).to match(%r{<td>certain</td>\n.+<td>aa</td>\n.+<td>SELECT 2</td>\n.+<td>lala.rb</td>})
        expect(html).to match(%r{<td>certain</td>\n.+<td>bb</td>\n.+<td>SELECT 1</td>\n.+<td>popo.rb</td>})
        expect(html).to match(%r{<td>uncertain</td>\n.+<td>aa</td>\n.+<td>SELECT 1</td>\n.+<td>popo.rb</td>})

        expect(stdout_spy).to have_received(:puts).with(/Report exported to/)
      end
    end
  end
end

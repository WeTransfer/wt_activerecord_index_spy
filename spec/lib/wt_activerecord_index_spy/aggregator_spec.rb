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
          aggregator.add(build_item(identifier: "any", query: query, certainity_level: :certain))
          aggregator.add(build_item(identifier: "any", query: query, certainity_level: :certain))
        end

        expect(aggregator.certain_results.count).to eq(10)
      end
    end

    describe "#export_html_results" do
      it "returns an html with results ordered and unique" do
        aggregator = described_class.new
        aggregator.add(build_item(identifier: "cc", query: "SELECT 1", origin: "lala.rb", certainity_level: :certain))
        aggregator.add(build_item(identifier: "bb", query: "SELECT 2", origin: "lala.rb", certainity_level: :uncertain))
        aggregator.add(build_item(identifier: "cc", query: "SELECT 1", origin: "popo.rb", certainity_level: :certain))
        aggregator.add(build_item(identifier: "bb", query: "SELECT 41", origin: "popo.rb", certainity_level: :certain))
        aggregator.add(build_item(identifier: "aa", query: "SELECT 3", origin: "popo.rb", certainity_level: :certain))
        aggregator.add(build_item(identifier: "bb", query: "SELECT 4", origin: "popo.rb", certainity_level: :certain))

        file = Tempfile.new
        stdout_spy = spy
        aggregator.export_html_results(file, stdout: stdout_spy)
        file.open
        file.rewind
        html = file.read

        expect(html).to match(%r{<td>certain</td>\n.+<td>cc</td>\n.+<td>SELECT 1</td>\n.+<td>popo.rb</td>})
        expect(html).to match(%r{<td>uncertain</td>\n.+<td>bb</td>\n.+<td>SELECT 2</td>\n.+<td>lala.rb</td>})
        expect(html).not_to match(%r{<td>uncertain</td>\n.+<td>cc</td>\n.+<td>SELECT 2</td>\n.+<td>lala.rb</td>})

        # test elements order
        elements = html.scan(%r{<td>([^<]+)</td>})
        expect(elements).to eq([
                                 ["Level"], ["Identifier"], ["Query"], ["Origin"],
                                 ["certain"], ["aa"], ["SELECT 3"], ["popo.rb"],
                                 ["certain"], ["bb"], ["SELECT 4"], ["popo.rb"],
                                 ["certain"], ["bb"], ["SELECT 41"], ["popo.rb"],
                                 ["certain"], ["cc"], ["SELECT 1"], ["popo.rb"],
                                 ["uncertain"], ["bb"], ["SELECT 2"], ["lala.rb"],
                               ])

        expect(stdout_spy).to have_received(:puts).with(/Report exported to/)
      end
    end
  end
end

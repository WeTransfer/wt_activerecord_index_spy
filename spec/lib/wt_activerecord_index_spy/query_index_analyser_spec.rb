RSpec.describe WtActiverecordIndexSpy::QueryIndexAnalyser do
  describe '#analyse' do
    context "when the same query runs more than once" do
      it "analyses only the first one" do
        query = User.where(name: "lala").to_sql

        index_analyser = described_class.new

        result = index_analyser.analyse(query)
        expect(result).to eq(:critical)

        result = index_analyser.analyse(query)
        expect(result).to be_nil
      end
    end
  end
end

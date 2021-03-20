# frozen_string_literal: true

RSpec.describe WtActiverecordIndexSpy::QueryIndexAnalyser do
  describe "#analyse" do
    context "when the same query runs more than once" do
      it "analyses only the first one" do
        query = User.where(name: "lala").to_sql

        result = subject.analyse(query)
        expect(result).to eq(:certain)

        count_explains = 0
        callback = lambda do |_, _, _, _, payload|
          count_explains += 1 if payload[:sql].include?("explain")
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          result = subject.analyse(query)
        end

        expect(result).to eq(:certain)
        expect(count_explains).to eq(0)
      end
    end
  end
end

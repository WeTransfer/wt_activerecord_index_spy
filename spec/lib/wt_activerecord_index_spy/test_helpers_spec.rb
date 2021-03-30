# frozen_string_literal: true

RSpec.describe "test_helpers" do
  include WtActiverecordIndexSpy::TestHelpers

  describe "matcher have_used_db_indexes" do
    before do
      User.create(name: "lala")
    end

    it "shows an error when a query have not used an index" do
      expect { User.find_by(name: "lala") }.not_to have_used_db_indexes
    end

    it "returns successfully when a query have used an index" do
      expect { User.where(email: "aa@aa.com").to_a }.to have_used_db_indexes
    end

    context "when only_certains is true" do
      it "does not fail for uncertain analisis", only: [:mysql2] do
        City.create!(name: "Rio", id: 1)
        City.create!(name: "Santo Andre", id: 2)
        City.create!(name: "Maua", id: 3)

        User.create!(name: "Lala1", city_id: 1)
        User.create!(name: "Lala2", city_id: 2)
        User.create!(name: "Lala3", city_id: 1)

        cities = City.where(name: "Santo Andre")
        expect { User.where(city_id: cities).to_a }
          .to have_used_db_indexes(only_certains: true)
      end
    end

    it "unsubscribes event after using the matcher" do
      expect(ActiveSupport::Notifications)
        .to receive(:subscribe)
        .with(
          "sql.active_record",
          an_instance_of(WtActiverecordIndexSpy::NotificationListener)
        ).and_call_original

      expect(ActiveSupport::Notifications)
        .to receive(:unsubscribe)
        .and_call_original

      expect { User.find_by(name: "lala") }.not_to have_used_db_indexes

      WtActiverecordIndexSpy.reset_results

      User.find_by(name: "lala")

      expect(WtActiverecordIndexSpy.results).to be_empty
    end

    it "does not analyse the same query again" do
      expect { User.find_by(name: "lala") }.not_to have_used_db_indexes

      count_explains = 0
      callback = lambda do |_, _, _, _, payload|
        count_explains += 1 if payload[:sql].include?("explain")
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect { User.find_by(name: "lala") }.not_to have_used_db_indexes
      end

      expect(count_explains).to eq(0)
    end
  end
end

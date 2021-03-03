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
      expect { User.find_by(email: "aa@aa.com") }.to have_used_db_indexes
    end

    context "when only_certains is true" do
      it "does not fail for uncertain analisis" do
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
  end
end

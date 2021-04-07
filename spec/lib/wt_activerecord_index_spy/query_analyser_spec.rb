# frozen_string_literal: true

RSpec.describe WtActiverecordIndexSpy::QueryAnalyser do
  describe "#analyse" do
    context "when the same query runs more than once" do
      it "analyses only the first one", only: [:mysql2] do
        query = User.where(name: "lala").to_sql

        result = subject.analyse(sql: query)
        expect(result).to eq(:certain)

        count_explains = 0
        callback = lambda do |_, _, _, _, payload|
          count_explains += 1 if payload[:sql].include?("explain")
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          result = subject.analyse(sql: query)
        end

        expect(result).to eq(:certain)
        expect(count_explains).to eq(0)
      end
    end

    context "when a query does not use an index" do
      it "adds the query to the certain list", only: [:mysql2] do
        query = User.where(name: "lala").to_sql

        result = subject.analyse(sql: query)
        expect(result).to eq(:certain)
      end

      it "adds the query to the uncertain list", only: [:postgresql] do
        query = User.where(name: "lala").to_sql

        result = subject.analyse(sql: query)
        expect(result).to eq(:uncertain)
      end
    end

    context "specific cases for Postgres", only: [:postgresql] do
      it "returns uncertain when the limit is 1 (find_by) and it has an index" do
        # I didn't use find_by because it's not possible to do .find_by().to_sql
        # However, where().limit(1) will generate the same query!
        query = User.where(email: "lala@popo.com").limit(1).to_sql

        result = subject.analyse(sql: query)
        expect(result).to eq(:uncertain)
      end

      it "returns nil when not using limit and it has an index" do
        query = User.where(email: "lala@popo.com").to_sql

        result = subject.analyse(sql: query)
        expect(result).to eq(nil)
      end

      it "returns uncertain when x" do
        city = City.create!(name: "Santo Andre")
        _user = User.create!(city: city, name: "Lala")

        # TODO: a query abaixo esta dando certain na product-manager e nao deveria
        # SELECT "bundles".* FROM "bundles" WHERE "bundles"."plan_id" = 764438051

        query = User.where(city_id: city.id).to_sql
        result = subject.analyse(sql: query)

        expect(result).to eq(nil)
      end
    end
  end
end

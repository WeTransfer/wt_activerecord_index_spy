# frozen_string_literal: true

RSpec.describe MysqlIndexChecker do
  it "has a version number" do
    expect(MysqlIndexChecker::VERSION).not_to be nil
  end

  describe ".watch_queries" do
    around(:each) do |example|
      @aggregator = MysqlIndexChecker::Aggregator.new
      described_class.watch_queries(aggregator: @aggregator) do
        example.run
      end
    end

    context "when a query does not use an index" do
      it "raises MissingIndex " do
        User.find_by(name: "lala")

        expect(@aggregator.results[:critical]['User Load'])
          .to include("WHERE `users`.`name` = 'lala'")
      end
    end

    context "when a query uses the primary key index" do
      it "does not raise MissingIndex " do
        expect do
          User.find_by(id: 1)
        end.not_to raise_error
      end
    end

    context "when a query uses some index" do
      it "does not raise MissingIndex " do
        expect do
          User.find_by(email: "aa@aa.com")
        end.not_to raise_error
      end
    end

    context "when a query filter multiple fields with no index" do
      it "raises MissingIndex " do
        User.create(name: "lala", age: 20)
        User.create(name: "lala2", age: 10)

        expect do
          User.find_by(age: 20, name: "popo")
        end.to raise_error(described_class::MissingIndex)
      end
    end

    context "when EXPLAIN returns 'Impossible WHERE noticed after reading const tables'" do
      it "does not raise MissingIndex " do
        User.create(name: "lala", age: 20)

        expect do
          User.where(id: 1, email: "aa@aa.com", age: 20).to_a
        end.not_to raise_error
      end
    end

    context "when there is an index but the query returns all records" do
      it "does not raise MissingIndex " do
        User.create!(name: "Lala1", city_id: 1)
        User.create!(name: "Lala2", city_id: 1)
        User.create!(name: "Lala3", city_id: 1)

        expect do
          User.where(city_id: 1).to_a
        end.not_to raise_error
      end
    end

    context "when a query has index but a subquery does not" do
      it "raises MissingIndex " do
        City.create!(name: "Rio", id: 1)
        City.create!(name: "Santo Andre", id: 2)
        City.create!(name: "Maua", id: 3)

        User.create!(name: "Lala1", city_id: 1)
        User.create!(name: "Lala2", city_id: 2)
        User.create!(name: "Lala3", city_id: 1)

        expect do
          cities = City.where(name: "Santo Andre")
          User.where(city_id: cities).to_a
        end.to raise_error(described_class::MissingIndex, /WHERE `users`.`city_id/)
      end
    end
  end
end

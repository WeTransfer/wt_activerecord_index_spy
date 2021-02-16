# frozen_string_literal: true

RSpec.describe MysqlIndexChecker do
  it "has a version number" do
    expect(MysqlIndexChecker::VERSION).not_to be nil
  end

  describe ".enable_raise_error_on_missing_index" do
    around(:each) do |example|
      described_class.raise_error_on_missing_index do
        example.run
      end
    end

    context "when a query does not use an index" do
      it "raises MissingIndex " do
        begin
          User.find_by(name: "lala")

          raise "this test should have raised an error"
        rescue described_class::MissingIndex => e
          expect(e.message).to include("WHERE `users`.`name` = 'lala'")
        end
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
  end
end

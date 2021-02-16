# frozen_string_literal: true

RSpec.describe MysqlIndexChecker do
  it "has a version number" do
    expect(MysqlIndexChecker::VERSION).not_to be nil
  end

  describe ".check_and_raise_error" do
    context "when a query does not use an index" do
      it "raises MissingIndex " do
        begin
          described_class.check_and_raise_error do
            User.find_by(name: "lala")
          end

          raise "this test should have raised an error"
        rescue described_class::MissingIndex => e
          expect(e.message).to include("WHERE `users`.`name` = 'lala'")
        end
      end
    end

    context "when a query uses the primary key index" do
      it "does not raise MissingIndex " do
        expect do
          described_class.check_and_raise_error do
            User.find_by(id: 1)
          end
        end.not_to raise_error
      end
    end

    context "when a query uses some index" do
      it "does not raise MissingIndex " do
        expect do
          described_class.check_and_raise_error do
            User.find_by(email: "aa@aa.com")
          end
        end.not_to raise_error
      end
    end

    context "when a query filter multiple fields with no index" do
      it "raises MissingIndex " do
        User.create(name: "lala", age: 20)
        User.create(name: "lala2", age: 10)

        expect do
          described_class.check_and_raise_error do
            User.find_by(age: 20, name: "popo")
          end
        end.to raise_error(described_class::MissingIndex)
      end
    end
  end
end

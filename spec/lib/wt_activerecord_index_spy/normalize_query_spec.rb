RSpec.describe WtActiverecordIndexSpy::NormalizeQuery do
  describe '.call' do
    it 'replaces numbers in conditions by a_number' do
      query = "SELECT `users`.* FROM `users` WHERE `users`.`age` = 1000 or `age` > 3123 or `age` < 12 or `age` >= 21 or age <= 10"

      result = described_class.call(query)

      expect(result).to eq("SELECT `users`.* FROM `users` WHERE `users`.`age` = a_number or `age` > a_number or `age` < a_number or `age` >= a_number or age <= a_number")
    end
  end
end

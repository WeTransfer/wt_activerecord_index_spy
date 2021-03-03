require_relative '../../../lib/wt_activerecord_index_spy/test_helpers'

RSpec.describe 'test_helpers' do
  include WtActiverecordIndexSpy::TestHelpers

  describe 'matcher have_used_index' do
    before do
      User.create(name: 'lala')
    end

    it 'shows an error when a query have not used an index' do
      expect { User.find_by(name: "lala") }.not_to have_used_index
    end

    it 'returns successfully when a query have used an index' do
      expect { User.find_by(email: "aa@aa.com") }.to have_used_index
    end
  end
end

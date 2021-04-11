# frozen_string_literal: true

# This class should not be required by the library because
# it's used only by tests.
# It should be placed in spec/support, but there is a test that
# checks the origin of the query, which would return true if
# the file was located in a "spec/" folder.
class User < ActiveRecord::Base
  belongs_to :city

  def self.some_method_with_a_query_missing_index
    find_by(name: "any")
  end
end

class City < ActiveRecord::Base
end

# frozen_string_literal: true

class User < ActiveRecord::Base
  def self.some_method_with_a_query_missing_index
    find_by(name: "any")
  end
end

class City < ActiveRecord::Base
end

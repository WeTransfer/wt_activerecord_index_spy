# class MysqlModel < ActiveRecord::Base
#   self.abstract_class = true

#   connects_to database: { writing: :mysql, reading: :mysql }
# end

class User < ActiveRecord::Base
  establish_connection(:mysql)

  def self.some_method_with_a_query_missing_index
    find_by(name: "any")
  end
end

class City < ActiveRecord::Base
  establish_connection(:mysql)
end

class UserPostgres < ActiveRecord::Base
  establish_connection(:postgres)

  def self.some_method_with_a_query_missing_index
    find_by(name: "any")
  end
end

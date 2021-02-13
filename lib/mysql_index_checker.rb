# frozen_string_literal: true

require_relative "mysql_index_checker/version"

module MysqlIndexChecker
  QueryNotUsingIndex = Class.new(StandardError)

  def self.raise_error_when_a_query_does_not_use_an_index
    yield
  end
end

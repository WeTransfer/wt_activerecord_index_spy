# frozen_string_literal: true

require_relative "mysql_index_checker/version"
require_relative "mysql_index_checker/index_verifier"

module MysqlIndexChecker
  QueryNotUsingIndex = Class.new(StandardError)

  def self.check_and_raise_error
    index_verifier = IndexVerifier.new

    ActiveSupport::Notifications
      .subscribe('sql.active_record', index_verifier)

    yield

    if index_verifier.queries_missing_index.count > 0
      raise QueryNotUsingIndex, index_verifier.queries_missing_index
    end
  end
end

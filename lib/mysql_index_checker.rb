# frozen_string_literal: true

require_relative "mysql_index_checker/version"
require_relative "mysql_index_checker/index_verifier"

# This is the top level module which requires everything
module MysqlIndexChecker
  def self.check_and_raise_error
    index_verifier = IndexVerifier.new

    ActiveSupport::Notifications
      .subscribe("sql.active_record", index_verifier)

    yield
  end
end

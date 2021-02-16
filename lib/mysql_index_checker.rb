# frozen_string_literal: true

require_relative "mysql_index_checker/version"
require_relative "mysql_index_checker/index_verifier"

# This is the top level module which requires everything
module MysqlIndexChecker
  def self.raise_error_on_missing_index
    index_verifier = IndexVerifier.new

    subscriber = ActiveSupport::Notifications
                 .subscribe("sql.active_record", index_verifier)

    yield

    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end

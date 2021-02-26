# frozen_string_literal: true

require_relative "mysql_index_checker/version"
require_relative "mysql_index_checker/aggregator"
require_relative "mysql_index_checker/index_verifier"

# This is the top level module which requires everything
module MysqlIndexChecker
  extend self

  def aggregator
    @aggregator ||= Aggregator.new
  end

  def watch_queries(aggregator: self.aggregator)
    index_verifier = IndexVerifier.new(aggregator: aggregator)

    subscriber = ActiveSupport::Notifications
                 .subscribe("sql.active_record", index_verifier)

    if block_given?
      yield

      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end

  def export_html_results
    aggregator.export_html_results
  end
end

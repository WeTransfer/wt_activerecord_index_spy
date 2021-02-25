# frozen_string_literal: true

require_relative "mysql_index_checker/version"
require_relative "mysql_index_checker/aggregator"
require_relative "mysql_index_checker/index_verifier"

# This is the top level module which requires everything
module MysqlIndexChecker
  extend self

  def watch_queries(aggregator: Aggregator.new)
    index_verifier = IndexVerifier.new(aggregator: aggregator)

    subscriber = ActiveSupport::Notifications
                 .subscribe("sql.active_record", index_verifier)

    yield

    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  def spy_queries_and_enqueue(aggregator: Aggregator.new)
    @index_verifier = IndexVerifier.new(
      aggregator: aggregator,
      postpone_analysis: true
    )

    subscriber = ActiveSupport::Notifications
                 .subscribe("sql.active_record", @index_verifier)
  end

  def analyse_enqueued_queries
    @index_verifier.analyse_enqueued_queries

    @index_verifier.aggregator
  end
end

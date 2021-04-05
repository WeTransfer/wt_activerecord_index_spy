# frozen_string_literal: true

require_relative "wt_activerecord_index_spy/version"
require_relative "wt_activerecord_index_spy/aggregator"
require_relative "wt_activerecord_index_spy/query_analyser"
require_relative "wt_activerecord_index_spy/query_analyser/mysql"
require_relative "wt_activerecord_index_spy/query_analyser/postgres"
require_relative "wt_activerecord_index_spy/notification_listener"
require "logger"

# This is the top level module which requires everything
module WtActiverecordIndexSpy
  extend self

  attr_accessor :logger

  def aggregator
    @aggregator ||= Aggregator.new
  end

  def query_analyser
    @query_analyser ||= QueryAnalyser.new
  end

  # rubocop:disable Metrics/MethodLength
  def watch_queries(
    aggregator: self.aggregator,
    ignore_queries_originated_in_test_code: true,
    query_analyser: self.query_analyser
  )
    aggregator.reset

    notification_listener = NotificationListener.new(
      aggregator: aggregator,
      ignore_queries_originated_in_test_code: ignore_queries_originated_in_test_code,
      query_analyser: query_analyser
    )

    subscriber = ActiveSupport::Notifications
                 .subscribe("sql.active_record", notification_listener)

    return unless block_given?

    yield

    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
  # rubocop:enable Metrics/MethodLength

  def export_html_results(file = nil, stdout: $stdout)
    aggregator.export_html_results(file, stdout: stdout)
  end

  def results
    aggregator.results
  end

  def reset_results
    aggregator.reset
  end

  def boot
    @logger = Logger.new("/dev/null")
  end
end

WtActiverecordIndexSpy.boot

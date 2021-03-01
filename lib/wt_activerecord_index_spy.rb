# frozen_string_literal: true

require_relative "wt_activerecord_index_spy/version"
require_relative "wt_activerecord_index_spy/aggregator"
require_relative "wt_activerecord_index_spy/notification_listener"
require "logger"

# This is the top level module which requires everything
module WtActiverecordIndexSpy
  extend self

  attr_accessor :ignore_queries_originated_in_test_code, :logger

  def aggregator
    @aggregator ||= Aggregator.new
  end

  def watch_queries(aggregator: self.aggregator)
    notification_listener = NotificationListener.new(aggregator: aggregator)

    subscriber = ActiveSupport::Notifications
                 .subscribe("sql.active_record", notification_listener)

    return unless block_given?

    yield

    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  def export_html_results(file = nil, stdout: $stdout)
    aggregator.export_html_results(file, stdout: stdout)
  end

  def boot
    @ignore_queries_originated_in_test_code = true
    @logger = Logger.new("/dev/null")
  end
end

WtActiverecordIndexSpy.boot

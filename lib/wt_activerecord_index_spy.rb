# frozen_string_literal: true

require_relative "wt_activerecord_index_spy/version"
require_relative "wt_activerecord_index_spy/aggregator"
require_relative "wt_activerecord_index_spy/index_verifier"

# This is the top level module which requires everything
module WtActiverecordIndexSpy
  extend self

  attr_accessor :ignore_queries_originated_in_test_code

  def aggregator
    @aggregator ||= Aggregator.new
  end

  def watch_queries(aggregator: self.aggregator)
    index_verifier = IndexVerifier.new(aggregator: aggregator)

    subscriber = ActiveSupport::Notifications
                 .subscribe("sql.active_record", index_verifier)

    return unless block_given?

    yield

    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  def export_html_results
    aggregator.export_html_results
  end
end

WtActiverecordIndexSpy.ignore_queries_originated_in_test_code = true

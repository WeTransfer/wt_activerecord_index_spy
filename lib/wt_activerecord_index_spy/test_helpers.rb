# frozen_string_literal: true

module WtActiverecordIndexSpy
  # This module defines the helper have_used_db_indexes to use in RSpec tests
  module TestHelpers
    extend RSpec::Matchers::DSL

    matcher :have_used_db_indexes do |only_certains: false|
      match do |actual|
        WtActiverecordIndexSpy.watch_queries(ignore_queries_originated_in_test_code: false)
        actual.call
        if only_certains
          WtActiverecordIndexSpy.results.certains.empty?
        else
          WtActiverecordIndexSpy.results.empty?
        end
      end

      failure_message do |_actual|
        "Some queries have not used indexes: #{WtActiverecordIndexSpy.results.to_h}"
      end

      def supports_block_expectations?
        true
      end
    end
  end
end
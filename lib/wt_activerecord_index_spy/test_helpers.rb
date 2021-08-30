# typed: false
# frozen_string_literal: true

require "rspec/matchers"

module WtActiverecordIndexSpy
  # This module defines the helper have_used_db_indexes to use in RSpec tests
  module TestHelpers
    extend RSpec::Matchers::DSL

    matcher :have_used_db_indexes do |only_certains: false|
      match do |actual|
        WtActiverecordIndexSpy.watch_queries(ignore_queries_originated_in_test_code: false) do
          actual.call
        end

        if only_certains
          WtActiverecordIndexSpy.certain_results.empty?
        else
          WtActiverecordIndexSpy.results.empty?
        end
      end

      failure_message do |_actual|
        "Some queries have not used indexes: #{WtActiverecordIndexSpy.results.to_h}"
      end

      failure_message_when_negated do |_actual|
        "All queries have used indexes and this was not expected"
      end

      def supports_block_expectations?
        true
      end
    end
  end
end

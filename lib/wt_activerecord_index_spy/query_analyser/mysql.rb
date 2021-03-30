# frozen_string_literal: true

module WtActiverecordIndexSpy
  class QueryAnalyser
    # It analyses the result of an EXPLAIN query to see if any index is missing.
    module Mysql
      extend self

      ALLOWED_EXTRA_VALUES = [
        # https://bugs.mysql.com/bug.php?id=64197
        "Impossible WHERE noticed after reading const tables",
        "no matching row"
      ].freeze

      # rubocop: disable Metrics/MethodLength
      def analyse(results, query:)
        analysed_queries = {}

        results.each do |result|
          certainity_level = analyse_explain(result)

          if certainity_level
            # The result is cached to not run the EXPLAIN query again in the
            # future
            analysed_queries[query] = certainity_level
            # Some queries are composed of subqueries, but for now we will
            # stop when one of them does not use index
            break
          else
            analysed_queries[query] = nil
          end
        end

        analysed_queries
      end
      # rubocop: enable Metrics/MethodLength

      private

      # rubocop: disable Metrics/CyclomaticComplexity
      # rubocop: disable Metrics/PerceivedComplexity
      def analyse_explain(result)
        type = result.fetch("type")
        possible_keys = result.fetch("possible_keys")
        key = result.fetch("key")
        extra = result.fetch("Extra")

        # more details about the result in https://dev.mysql.com/doc/refman/8.0/en/explain-output.html
        return if type == "ref"
        return if ALLOWED_EXTRA_VALUES.any? { |value| extra&.include?(value) }

        return :certain if possible_keys.nil?
        return :uncertain if possible_keys == "PRIMARY" && key.nil? && type == "ALL"
      end
      # rubocop: enable Metrics/CyclomaticComplexity
      # rubocop: enable Metrics/PerceivedComplexity
    end
  end
end

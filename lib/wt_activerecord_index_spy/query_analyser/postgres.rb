# frozen_string_literal: true

module WtActiverecordIndexSpy
  class QueryAnalyser
    # It analyses the result of an EXPLAIN query to see if any index is missing.
    module Postgres
      extend self

      def analyse(results, query:)
        WtActiverecordIndexSpy.logger.debug("results:\n#{results.rows.join("\n")}")

        full_results = results.rows.join(", ").downcase

        if full_results.include?("seq scan on")
          # Postgres uses a seq scan for queries with LIMIT even when the table has an
          # index to be used. More details here: https://www.postgresql.org/message-id/17689.1098648713%40sss.pgh.pa.us
          return :uncertain if full_results.include?("limit")

          return :certain
        end
      end
    end
  end
end

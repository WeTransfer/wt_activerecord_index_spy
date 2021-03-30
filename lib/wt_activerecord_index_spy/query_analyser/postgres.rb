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
          # Potgres use a seq scan for LIMIT queries even when the table has an
          # index to be used. More details here: https://www.postgresql.org/message-id/17689.1098648713%40sss.pgh.pa.us
          return { query => :uncertain } if full_results.include?("limit")

          return { query => :certain }
        end

        {}
      end
    end
  end
end

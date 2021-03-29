# frozen_string_literal: true

module WtActiverecordIndexSpy
  class QueryAnalyser
    # It analyses the result of an EXPLAIN query to see if any index is missing.
    module Postgres
      extend self

      def analyse(results, query:)
        WtActiverecordIndexSpy.logger.debug("results:\n" + results.rows.join("\n"))

        full_results = results.rows.join(", ").downcase

        if full_results.include?("filter") && full_results.include?("seq scan on")
          return { query => :certain }
        end

        #TODO: todo
        return {}
      end
    end
  end
end

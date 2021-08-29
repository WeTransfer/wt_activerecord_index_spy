# typed: false
# frozen_string_literal: true

module WtActiverecordIndexSpy
  class QueryAnalyser
    # It analyses the result of an EXPLAIN query to see if any index is missing.
    module Postgres
      extend self

      def analyse(results)
        WtActiverecordIndexSpy.logger.debug("results:\n#{results.rows.join("\n")}")

        full_results = results.rows.join(", ").downcase

        # rubocop:disable Layout/LineLength
        # Postgres sometimes uses a "seq scan" even for queries that could use an index.
        # So it's almost impossible to be certain if an index is missing!
        # The result of the EXPLAIN query varies depending on the state of the database
        # because Postgres collects statistics from tables and decide if it's better
        # using an index or not based on that.
        # This is an example in a real application:
        #
        # [1] pry(main)> Feature.where(plan_id: 312312).explain
        #   Feature Load (4.0ms)  SELECT "features".* FROM "features" WHERE "features"."plan_id" = $1  [["plan_id", 312312]]
        # => EXPLAIN for: SELECT "features".* FROM "features" WHERE "features"."plan_id" = $1 [["plan_id", 312312]]
        #                        QUERY PLAN
        # ---------------------------------------------------------
        #  Seq Scan on features  (cost=0.00..1.06 rows=1 width=72)
        #    Filter: (plan_id = 312312)
        # (2 rows)
        #
        # [2] pry(main)> Feature.count
        #    (2.8ms)  SELECT COUNT(*) FROM "features"
        # => 5
        # [3] pry(main)> Plan.count
        #    (2.7ms)  SELECT COUNT(*) FROM "plans"
        # => 2
        #
        ####################################################################################################################
        #
        # [1] pry(main)> Feature.where(plan_id: 312312).explain
        #   Feature Load (2.3ms)  SELECT "features".* FROM "features" WHERE "features"."plan_id" = $1  [["plan_id", 312312]]
        # => EXPLAIN for: SELECT "features".* FROM "features" WHERE "features"."plan_id" = $1 [["plan_id", 312312]]
        #                                        QUERY PLAN
        # ----------------------------------------------------------------------------------------
        #  Bitmap Heap Scan on features  (cost=4.18..12.64 rows=4 width=72)
        #    Recheck Cond: (plan_id = 312312)
        #    ->  Bitmap Index Scan on index_features_on_plan_id  (cost=0.00..4.18 rows=4 width=0)
        #          Index Cond: (plan_id = 312312)
        # rubocop:enable Layout/LineLength
        return :uncertain if full_results.include?("seq scan on")
      end
    end
  end
end

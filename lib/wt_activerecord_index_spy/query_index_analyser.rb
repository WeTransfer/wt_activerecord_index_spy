# frozen_string_literal: true

module WtActiverecordIndexSpy
  # It runs an EXPLAIN query given a query and analyses the result to see if
  # some index is missing.
  class QueryIndexAnalyser
    def initialize
      # This is a cache to not run the same EXPLAIN again
      # It sets the query as key and the result (certain, uncertain) as the value
      @analysed_queries = {}
    end

    # rubocop:disable Metrics/MethodLength
    def analyse(query)
      # TODO: this could be more intelligent to not duplicate similar queries
      # with different WHERE values, example:
      # - WHERE lala = 1 AND popo = 1
      # - WHERE lala = 2 AND popo = 2
      return @analysed_queries[query] if @analysed_queries.has_key?(query)

      # We need a thread to use a different connection that it's used by the
      # application otherwise, it can change some ActiveRecord internal state
      # such as number_of_affected_rows that is returned by the method
      # `update_all`
      Thread.new do
        results = ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.query("explain #{query}")
        end

        # The find is used to stop the loop when it's found the first query
        # which does not use indexes
        results.find do |result|
          certainity_level = analyse_explain(result)

          if certainity_level
            # The result is cached to not run the EXPLAIN query again in the
            # future
            @analysed_queries[query] = certainity_level
            # Some queries are composed of subqueries, but for now we will
            # stop when one of them does not use index
            break certainity_level
          else
            @analysed_queries[query] = nil
          end
        end
      end.join.value
    end
    # rubocop:enable Metrics/MethodLength

    private

    ALLOWED_EXTRA_VALUES = [
      # https://bugs.mysql.com/bug.php?id=64197
      "Impossible WHERE noticed after reading const tables",
      "no matching row"
    ].freeze

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def analyse_explain(result)
      _id, _select_type, _table, _partitions, type, possible_keys, key, _key_len,
        _ref, _rows, _filtered, extra = result

      # more details about the result in https://dev.mysql.com/doc/refman/8.0/en/explain-output.html
      return if type == "ref"
      return if ALLOWED_EXTRA_VALUES.any? { |value| extra&.include?(value) }

      return :certain if possible_keys.nil?
      return :uncertain if possible_keys == "PRIMARY" && key.nil? && type == "ALL"
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end
end

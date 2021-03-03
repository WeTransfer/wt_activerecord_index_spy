# frozen_string_literal: true

module WtActiverecordIndexSpy
  # It runs an EXPLAIN query given a query and analyses the result to see if
  # some index is missing.
  class QueryIndexAnalyser
    def initialize
      @analysed_queries = Set.new
    end

    # rubocop:disable Metrics/MethodLength
    def analyse(query)
      # TODO: this could be more intelligent to not duplicate similar queries
      # with different WHERE values, example:
      # - WHERE lala = 1 AND popo = 1
      # - WHERE lala = 2 AND popo = 2
      return if @analysed_queries.include?(query)
      @analysed_queries << query

      # We need a thread to use a different connection that it's used by the
      # application otherwise, it can change some ActiveRecord internal state
      # such as number_of_affected_rows that is returned by the method
      # `update_all`
      Thread.new do
        results = ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.query("explain #{query}")
        end

        results.find do |result|
          criticality_level = analyse_explain(result)
          break criticality_level if criticality_level
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

      return :critical if possible_keys.nil?
      return :warning if possible_keys == "PRIMARY" && key.nil? && type == "ALL"
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end
end

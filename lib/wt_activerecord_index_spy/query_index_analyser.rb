module WtActiverecordIndexSpy
  class QueryIndexAnalyser
    def initialize
      @analysed_queries = Set.new
    end

    def analyse(query)
      # TODO: this could be more intelligent to not duplicate similar queries
      # with different WHERE values, example:
      # - WHERE lala = 1 AND popo = 1
      # - WHERE lala = 2 AND popo = 2
      return if @analysed_queries.include?(query)

      Thread.new do
        # more details about the result https://dev.mysql.com/doc/refman/8.0/en/explain-output.html
        results = ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.query("explain #{query}")
        end
        @analysed_queries << query

        results.find do |result|
          criticality_level = analyse_explain(result)
          break criticality_level if criticality_level
        end
      end.join.value
    end

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

      return if type == "ref"
      return if ALLOWED_EXTRA_VALUES.any? { |value| extra&.include?(value) }

      return :critical if possible_keys.nil?
      return :warning if possible_keys == "PRIMARY" && key.nil? && type == "ALL"
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end
end

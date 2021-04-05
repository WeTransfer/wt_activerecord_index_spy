# frozen_string_literal: true

module WtActiverecordIndexSpy
  # It runs an EXPLAIN query given a query and analyses the result to see if
  # some index is missing.
  class QueryAnalyser
    def initialize
      # This is a cache to not run the same EXPLAIN again
      # It sets the query as key and the result (certain, uncertain) as the value
      @analysed_queries = {}
    end

    # The sql and type_casted_binds vary depend on the adapter.
    # - Mysql2: sends sql complete and type_casted_binds = []
    # - Postregs: sends sql in a form of prepared statement and its values in type_casted_binds
    #
    # rubocop:disable Metrics/MethodLength
    def analyse(sql:, connection: ActiveRecord::Base.connection, binds: [])
      query = sql
      # TODO: this could be more intelligent to not duplicate similar queries
      # with different WHERE values, example:
      # - WHERE lala = 1 AND popo = 1
      # - WHERE lala = 2 AND popo = 2
      # Notes:
      # - The Postgres adapter uses prepared statements as default, so it
      # will save the queries without the values.
      # - The Mysql2 adapter does not use prepared statements as default, so it
      # will analyse very similar queries as described above.
      # TODO: check if it is caching prepared statements (it should)
      return @analysed_queries[query] if @analysed_queries.key?(query)

      adapter = select_adapter(connection)

      # We need a thread to use a different connection that it's used by the
      # application otherwise, it can change some ActiveRecord internal state
      # such as number_of_affected_rows that is returned by the method
      # `update_all`
      Thread.new do
        results = ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.exec_query("EXPLAIN #{query}", "SQL", binds)
        end

        # The find is used to stop the loop when it's found the first query
        # which does not use indexes
        result_explain_analisis = adapter.analyse(results, query: query)
        @analysed_queries.merge(result_explain_analisis)

        non_nil = result_explain_analisis.find { |_k, v| !v.nil? }
        non_nil && non_nil[1]
      end.join.value
    end
    # rubocop:enable Metrics/MethodLength

    private

    def select_adapter(connection)
      case connection.adapter_name
      when "Mysql2"
        QueryAnalyser::Mysql
      when "PostgreSQL"
        QueryAnalyser::Postgres
      else
        raise NotImplementedError, "adapter: #{ActiveRecord::Base.connection.adapter_name}"
      end
    end
  end
end

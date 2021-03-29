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
    def analyse(sql:, connection: ActiveRecord::Base.connection, type_casted_binds: [])
      query = sql
      # TODO: this could be more intelligent to not duplicate similar queries
      # with different WHERE values, example:
      # - WHERE lala = 1 AND popo = 1
      # - WHERE lala = 2 AND popo = 2
      return @analysed_queries[query] if @analysed_queries.key?(query)

      adapter = select_adapter(connection)

      # query_with_values = query
      # if type_casted_binds.any?
      #   query_with_values =
      # end

      # We need a thread to use a different connection that it's used by the
      # application otherwise, it can change some ActiveRecord internal state
      # such as number_of_affected_rows that is returned by the method
      # `update_all`
      Thread.new do
        results = ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.exec_query("EXPLAIN #{query}", 'SQL', type_casted_binds, prepare: true)
        end

        # The find is used to stop the loop when it's found the first query
        # which does not use indexes
        results.find do |result|
          certainity_level = adapter.analyse_explain(result)

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

    def select_adapter(connection)
      case connection.adapter_name
      when 'Mysql2'
        QueryAnalyser::Mysql
      when 'PostgreSQL'
        QueryAnalyser::Postgres
      else
        raise NotImplementedError, "adapter: #{ActiveRecord::Base.connection.adapter_name}"
      end
    end
  end
end
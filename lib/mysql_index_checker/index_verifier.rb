# frozen_string_literal: true

module MysqlIndexChecker
  MissingIndex = Class.new(StandardError)

  # This class can be used to subscribe to an activerecord "sql.active_record"
  # notification.
  # It gets each query that uses a WHERE statement and runs a EXPLAIN query to
  # see if it uses an index.
  class IndexVerifier
    IGNORED_SQL = [
      /^PRAGMA (?!(table_info))/,
      /^SELECT currval/,
      /^SELECT CAST/,
      /^SELECT @@IDENTITY/,
      /^SELECT @@ROWCOUNT/,
      /^SAVEPOINT/,
      /^ROLLBACK TO SAVEPOINT/,
      /^RELEASE SAVEPOINT/,
      /^SHOW max_identifier_length/,
      /^SELECT @@FOREIGN_KEY_CHECKS/,
      /^SET FOREIGN_KEY_CHECKS/,
      /^TRUNCATE TABLE/
    ].freeze

    attr_reader :queries_missing_index, :aggregator

    def initialize(aggregator:, postpone_analysis: false)
      @queries_missing_index = []
      @aggregator = aggregator
      @analyzed_queries = Set.new
      @postpone_analysis = postpone_analysis
      @queries_to_analyze = Set.new
    end

    def call(_name, _start, _finish, _message_id, values)
      query = values[:sql]
      query_identifier = values[:name]

      return if ignore_query?(query: query, name: values[:name])

      # TODO: this could be more intelligent to not duplicate similar queries
      # with different WHERE values, example:
      # - WHERE lala = 1 AND popo = 1
      # - WHERE lala = 2 AND popo = 2
      return if @analyzed_queries.include?(query)

      if @postpone_analysis
        @queries_to_analyze << { query: query, identifier: query_identifier }
      else
        analyse_query(query: query, identifier: query_identifier)
      end
    end

    def analyse_enqueued_queries
      @queries_to_analyze.each do |item|
        analyse_query(**item)
      end
    end

    private

    ALLOWED_EXTRA_VALUES = [
      # https://bugs.mysql.com/bug.php?id=64197
      "Impossible WHERE noticed after reading const tables",
      "no matching row"
    ].freeze

    def analyse_query(query:, identifier:)
      # more details about the result https://dev.mysql.com/doc/refman/8.0/en/explain-output.html
      results = ActiveRecord::Base.connection.query("explain #{query}")
      @analyzed_queries << query

      results.each do |result|
        analyse_explain(
          result: result,
          identifier: identifier,
          query: query
        )
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def analyse_explain(result:, identifier:, query:)
      _id, _select_type, _table, _partitions, type, possible_keys, key, _key_len,
        _ref, _rows, _filtered, extra = result

      return if type == "ref"
      return if ALLOWED_EXTRA_VALUES.any? { |value| extra&.include?(value) }

      if possible_keys.nil?
        @aggregator.add_critical(identifier: identifier, query: query)
        return
      end

      if possible_keys == "PRIMARY" && key.nil? && type == "ALL"
        @aggregator.add_warning(identifier: identifier, query: query)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def ignore_query?(name:, query:)
      # FIXME: this seems bad. we should probably have a better way to indicate
      # the query was cached
      name == "CACHE" ||
        name == "SCHEMA" ||
        name.blank? ||
        !query.downcase.include?("where") ||
        IGNORED_SQL.any? { |r| query =~ r }
    end
  end
end

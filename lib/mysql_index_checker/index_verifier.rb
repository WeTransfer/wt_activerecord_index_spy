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

    attr_reader :queries_missing_index

    def initialize(aggregator: Aggregator.new)
      @queries_missing_index = []
      @aggregator = aggregator
    end

    def call(_name, _start, _finish, _message_id, values)
      sql = values[:sql]
      query_identifier = values[:name]
      return unless analyse_query?(sql: sql, name: values[:name])

      # more details about the result https://dev.mysql.com/doc/refman/8.0/en/explain-output.html
      #TODO: skip queries already analysed
      results = ActiveRecord::Base.connection.query("explain #{sql}")
      results.each do |result|
        analyse_explain(
          result: result,
          identifier: query_identifier,
          query: sql
        )
      end
    end

    private

    ALLOWED_EXTRA_VALUES = [
      # https://bugs.mysql.com/bug.php?id=64197
      "Impossible WHERE noticed after reading const tables",
      "no matching row"
    ].freeze

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

    def analyse_query?(name:, sql:)
      # FIXME: this seems bad. we should probably have a better way to indicate
      # the query was cached
      name != "CACHE" &&
        name != "SCHEMA" &&
        name.present? &&
        sql.downcase.include?("where") &&
        IGNORED_SQL.none? { |r| sql =~ r }
    end
  end
end

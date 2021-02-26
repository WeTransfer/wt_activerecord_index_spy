# frozen_string_literal: true

module WtActiverecordIndexSpy
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
      @analysed_queries = Set.new
    end

    def call(_name, _start, _finish, _message_id, values)
      query = values[:sql]
      identifier = values[:name]
      return if ignore_query?(query: query, name: identifier)

      origin = caller.find { |line| !line.include?('/gems/') }

      if WtActiverecordIndexSpy.ignore_queries_originated_in_test_code
        # Hopefully, it will get the line which executed the query.
        # It ignores activerecord, activesupport and other gem frames.
        # Maybe there is a better way to achieve it
        return if origin.include?('_spec')
      end

      # TODO: this could be more intelligent to not duplicate similar queries
      # with different WHERE values, example:
      # - WHERE lala = 1 AND popo = 1
      # - WHERE lala = 2 AND popo = 2
      return if @analysed_queries.include?(query)

      # more details about the result https://dev.mysql.com/doc/refman/8.0/en/explain-output.html
      results = ActiveRecord::Base.connection.query("explain #{query}")
      @analysed_queries << query

      results.each do |result|
        if level = analyse_explain(result)
          @aggregator.send(
            "add_#{level}",
            Aggregator::Item.new(identifier: identifier, query: query, origin: origin)
          )
        end
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

    def ignore_query?(name:, query:)
      # FIXME: this seems bad. we should probably have a better way to indicate
      # the query was cached
      name == "CACHE" ||
        name == "SCHEMA" ||
        !name ||
        !query.downcase.include?("where") ||
        IGNORED_SQL.any? { |r| query =~ r }
    end
  end
end

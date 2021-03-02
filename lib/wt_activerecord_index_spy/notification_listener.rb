# frozen_string_literal: true

module WtActiverecordIndexSpy
  MissingIndex = Class.new(StandardError)

  # This class can be used to subscribe to an activerecord "sql.active_record"
  # notification.
  # It gets each query that uses a WHERE statement and runs a EXPLAIN query to
  # see if it uses an index.
  class NotificationListener
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

    # TODO: refactor me pls to remove all these Rubocop warnings!
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    def call(_name, _start, _finish, _message_id, values)
      query = values[:sql]
      logger.debug "query: #{query}"
      identifier = values[:name]

      if ignore_query?(query: query, name: identifier)
        logger.debug "query type ignored"
        return
      end
      logger.debug "query type accepted"

      origin = caller.find { |line| !line.include?("/gems/") }

      if WtActiverecordIndexSpy.ignore_queries_originated_in_test_code &&
         (origin.include?("_spec") || origin.include?("_test"))

        logger.debug "origin ignored: #{origin}"
        # Hopefully, it will get the line which executed the query.
        # It ignores activerecord, activesupport and other gem frames.
        # Maybe there is a better way to achieve it
        return
      end

      logger.debug "origin accepted: #{origin}"

      # TODO: this could be more intelligent to not duplicate similar queries
      # with different WHERE values, example:
      # - WHERE lala = 1 AND popo = 1
      # - WHERE lala = 2 AND popo = 2
      # TODO: look values to see if there is an uninterpolated query
      return if @analysed_queries.include?(query)

      Thread.new do
        # more details about the result https://dev.mysql.com/doc/refman/8.0/en/explain-output.html
        results = ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.query("explain #{query}")
        end
        @analysed_queries << query

        results.each do |result|
          criticality_level = analyse_explain(result)
          next unless criticality_level

          @aggregator.send(
            "add_#{criticality_level}",
            Aggregator::Item.new(identifier: identifier, query: query, origin: reduce_origin(origin))
          )
        end
      end.join
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    private

    ALLOWED_EXTRA_VALUES = [
      # https://bugs.mysql.com/bug.php?id=64197
      "Impossible WHERE noticed after reading const tables",
      "no matching row"
    ].freeze

    def reduce_origin(origin)
      origin[0...origin.rindex(":")]
        .split("/")[-2..-1]
        .join("/")
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def analyse_explain(result)
      _id, _select_type, _table, _partitions, type, possible_keys, key, _key_len,
        _ref, _rows, _filtered, extra = result

      return if type == "ref"
      return if ALLOWED_EXTRA_VALUES.any? { |value| extra&.include?(value) }

      return :certain if possible_keys.nil?
      return :uncertain if possible_keys == "PRIMARY" && key.nil? && type == "ALL"
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

    def logger
      WtActiverecordIndexSpy.logger
    end
  end
end

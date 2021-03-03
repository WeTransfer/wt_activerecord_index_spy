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
      @query_index_analyser = QueryIndexAnalyser.new
    end

    # TODO: refactor me pls to remove all these Rubocop warnings!
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
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

      criticality_level = @query_index_analyser.analyse(query)
      return unless criticality_level

      @aggregator.send(
        "add_#{criticality_level}",
        Aggregator::Item.new(identifier: identifier, query: query, origin: reduce_origin(origin))
      )
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    private

    def ignore_query?(name:, query:)
      # FIXME: this seems bad. we should probably have a better way to indicate
      # the query was cached
      name == "CACHE" ||
        name == "SCHEMA" ||
        !name ||
        !query.downcase.include?("where") ||
        IGNORED_SQL.any? { |r| query =~ r }
    end

    def reduce_origin(origin)
      origin[0...origin.rindex(":")]
        .split("/")[-2..]
        .join("/")
    end

    def logger
      WtActiverecordIndexSpy.logger
    end
  end
end

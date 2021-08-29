# typed: true
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
      /^TRUNCATE TABLE/,
      /^EXPLAIN/,
      /FROM INFORMATION_SCHEMA/,
    ].freeze

    attr_reader :queries_missing_index

    def initialize(ignore_queries_originated_in_test_code:,
                   aggregator: Aggregator.new,
                   query_analyser: QueryAnalyser.new)
      @queries_missing_index = []
      @aggregator = aggregator
      @query_analyser = query_analyser
      @ignore_queries_originated_in_test_code = ignore_queries_originated_in_test_code
    end

    # TODO: refactor me pls to remove all these Rubocop warnings!
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def call(_name, _start, _finish, _message_id, values)
      query = values[:sql]
      logger.debug "query: #{query}"
      identifier = values[:name].to_s

      if ignore_query?(query: query, name: identifier)
        logger.debug "query type ignored, name: #{identifier}, query: #{query}"
        return
      end
      logger.debug "query type accepted"

      origin = caller.find { |line| !line.include?("/gems/") }
      if @ignore_queries_originated_in_test_code && query_originated_in_tests?(origin)
        logger.debug "origin ignored: #{origin}"
        # Hopefully, it will get the line which executed the query.
        # It ignores activerecord, activesupport and other gem frames.
        # Maybe there is a better way to achieve it
        return
      end

      logger.debug "origin accepted: #{origin}"

      certainity_level = @query_analyser.analyse(**values.slice(:sql, :connection, :binds))
      return unless certainity_level

      item = Aggregator::Item.new(
        identifier: identifier,
        query: query,
        origin: reduce_origin(origin),
        certainity_level: certainity_level
      )
      @aggregator.add(item)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    private

    # TODO: Find a better way to detect if the origin is a test file
    def query_originated_in_tests?(origin)
      origin.include?("spec/") ||
        origin.include?("test/")
    end

    def ignore_query?(name:, query:)
      # FIXME: this seems bad. we should probably have a better way to indicate
      # the query was cached
      name == "CACHE" ||
        name == "SCHEMA" ||
        !query.downcase.include?("where") ||
        IGNORED_SQL.any? { |r| query =~ r }
    end

    def reduce_origin(origin)
      origin[0...origin.rindex(":")]
        .split("/")[-2..-1]
        .join("/")
    end

    def logger
      WtActiverecordIndexSpy.logger
    end
  end
end

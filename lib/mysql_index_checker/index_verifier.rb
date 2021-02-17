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

    def initialize
      @queries_missing_index = []
    end

    def call(_name, _start, _finish, _message_id, values)
      sql = values[:sql]
      return unless analyse_query?(sql: sql, name: values[:name])

      # more details about the result https://dev.mysql.com/doc/refman/8.0/en/explain-output.html
      results = ActiveRecord::Base.connection.query("explain #{values[:sql]}")

      _id, _select_type, _table, _partitions, type, possible_keys, _key, _key_len,
        ref, _rows, _filtered, extra = results.first

      return if type == 'ref'

      # https://bugs.mysql.com/bug.php?id=64197
      return if extra&.include?("Impossible WHERE noticed after reading const tables")
      return if extra&.include?("no matching row")

      if possible_keys.nil?
        raise MissingIndex, "query: #{sql}, result: #{results}"
      end
    end

    private

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

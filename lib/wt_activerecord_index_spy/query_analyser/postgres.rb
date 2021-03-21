# frozen_string_literal: true

module WtActiverecordIndexSpy
  class QueryAnalyser
    # It analyses the result of an EXPLAIN query to see if any index is missing.
    module Postgres
      extend self

      def analyse_explain(result)
        _id, _select_type, _table, _partitions, type, possible_keys, key, _key_len,
          _ref, _rows, _filtered, extra = result

        #TODO: todo
      end
    end
  end
end

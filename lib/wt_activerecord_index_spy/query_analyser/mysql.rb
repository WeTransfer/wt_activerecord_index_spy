# frozen_string_literal: true

module WtActiverecordIndexSpy
  class QueryAnalyser
    # It analyses the result of an EXPLAIN query to see if any index is missing.
    module Mysql
      extend self

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

        # more details about the result in https://dev.mysql.com/doc/refman/8.0/en/explain-output.html
        return if type == "ref"
        return if ALLOWED_EXTRA_VALUES.any? { |value| extra&.include?(value) }

        return :certain if possible_keys.nil?
        return :uncertain if possible_keys == "PRIMARY" && key.nil? && type == "ALL"
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
    end
  end
end

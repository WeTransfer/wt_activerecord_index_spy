module MysqlIndexChecker
  class Aggregator
    attr_reader :results

    Result = Class.new(Struct.new(:criticals, :warnings, keyword_init: true))

    def initialize
      @results = Result.new(criticals: {}, warnings: {})
    end

    def add_critical(identifier:, query:)
      @results.criticals[identifier] ||= Set.new
      @results.criticals[identifier].add(query)
    end

    def add_warning(identifier:, query:)
      @results.warnings[identifier] ||= Set.new
      @results.warnings[identifier].add(query)
    end
  end
end

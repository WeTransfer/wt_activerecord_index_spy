module MysqlIndexChecker
  class Aggregator
    attr_reader :results

    def initialize
      @results = {
        critical: {},
        warning: {}
      }
    end

    def add(identifier:, level:, query:)
      @results[level][identifier] = query
    end
  end
end

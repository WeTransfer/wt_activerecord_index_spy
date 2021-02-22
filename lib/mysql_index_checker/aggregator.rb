require 'erb'

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

    def html_results
      ERB
        .new(
          File.read(File.join(File.dirname(__FILE__), './results.html.erb')),
          trim_mode: '-'
        )
        .result_with_hash(results: @results)
    end
  end
end

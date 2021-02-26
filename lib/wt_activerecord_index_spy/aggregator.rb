# frozen_string_literal: true

require "erb"
require "tmpdir"

module WtActiverecordIndexSpy
  # This class aggregates all queries that were considered not using index.
  # Since it's not possible to be sure for every query, it separated them in
  # different levels, such as warnings and criticals.
  class Aggregator
    attr_reader :results

    Result = Class.new(Struct.new(:criticals, :warnings, keyword_init: true))
    Item = Struct.new(:identifier, :query, :origin, keyword_init: true)

    def initialize
      @results = Result.new(criticals: Set.new, warnings: Set.new)
    end

    def add_critical(item)
      # TODO: this could be more intelligent to not duplicate similar queries
      # with different WHERE values, example:
      # - WHERE lala = 1 AND popo = 1
      # - WHERE lala = 2 AND popo = 2
      @results.criticals.add(item)
    end

    def add_warning(item)
      @results.warnings.add(item)
    end

    def export_html_results(file, stdout: $stdout)
      file = file || default_html_output_file
      content = ERB
                .new(
                  File.read(File.join(File.dirname(__FILE__), "./results.html.erb")),
                  trim_mode: "-"
                )
                .result_with_hash(results: @results)

      file.write(content)
      file.close
      stdout.puts "Report exported to #{file.path}"
    end

    private

    def default_html_output_file
      File.new(
        File.join(Dir.tmpdir, "wt_activerecord_index_spy-results.html"),
        "w"
      )
    end
  end
end

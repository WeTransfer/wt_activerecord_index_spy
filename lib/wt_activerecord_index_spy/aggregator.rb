# frozen_string_literal: true

require "erb"
require "tmpdir"

module WtActiverecordIndexSpy
  # This class aggregates all queries that were considered not using index.
  # Since it's not possible to be sure for every query, it separates the result
  # in certains and uncertains.
  class Aggregator
    attr_reader :results

    Item = Struct.new(:identifier, :query, :origin, :certainity_level, keyword_init: true)

    def initialize
      @results = {}
    end

    def reset
      @results = {}
    end

    # item: an instance of Aggregator::Item
    def add(item)
      @results[item.query] = item
    end

    def certain_results
      @results.map do |query, item|
        item if item.certainity_level == :certain
      end.compact
    end

    def uncertain_results
      @results.map do |query, item|
        item if item.certainity_level == :uncertain
      end.compact
    end

    def export_html_results(file, stdout: $stdout)
      file ||= default_html_output_file
      content = ERB.new(File.read(File.join(File.dirname(__FILE__), "./results.html.erb")), 0, "-")
                   .result_with_hash(certain_results: certain_results, uncertain_results: uncertain_results)

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

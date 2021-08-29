# typed: strict
# frozen_string_literal: true

require "erb"
require "tmpdir"

module WtActiverecordIndexSpy
  # This class aggregates all queries that were considered not using index.
  # Since it's not possible to be sure for every query, it separates the result
  # in certains and uncertains.
  class Aggregator
    extend T::Sig

    Results = T.type_alias { T::Hash[String, Item] }

    sig {returns(Results)}
    attr_reader :results

    class Item < T::Struct
      prop :identifier, String
      prop :query, String
      prop :origin, String
      prop :certainity_level, Symbol
    end

    sig {void}
    def initialize
      @results = T.let({}, Results)
    end

    sig {void}
    def reset
      @results = {}
      nil
    end

    sig {params(item: Item).returns(Item)}
    def add(item)
      @results[item.query] = item
    end

    sig {returns(T::Array[Item])}
    def certain_results
      @results.map do |_query, item|
        item if item.certainity_level == :certain
      end.compact
    end

    sig {returns(T::Array[Item])}
    def uncertain_results
      @results.map do |_query, item|
        item if item.certainity_level == :uncertain
      end.compact
    end

    sig do
      params(
        file: T.nilable(T.any(File, Tempfile)),
        stdout: IO
      )
      .void
      .checked(:compiled)
    end
    def export_html_results(file=nil, stdout: $stdout)
      file ||= default_html_output_file
      content = ERB.new(File.read(File.join(File.dirname(__FILE__), "./results.html.erb")), 0, "-")
                   .result_with_hash(certain_results: certain_results, uncertain_results: uncertain_results)

      file.write(content)
      file.close
      stdout.puts "Report exported to #{file.path}"
    end

    private

    sig {returns(File)}
    def default_html_output_file
      File.new(
        File.join(Dir.tmpdir, "wt_activerecord_index_spy-results.html"),
        "w"
      )
    end
  end
end

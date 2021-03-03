module WtActiverecordIndexSpy
  module TestHelpers
    extend RSpec::Matchers::DSL

    matcher :have_used_index do |expected|
      match do |actual|
        WtActiverecordIndexSpy.watch_queries
        actual.call
        WtActiverecordIndexSpy.results.empty?
      end

      failure_message do |_actual|
        "Some queries have not used indexes: " +
          WtActiverecordIndexSpy.results.to_h.to_s
      end

      supports_block_expectations
    end
  end
end

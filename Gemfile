# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in wt_activerecord_index_spy.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "rubocop", "~> 1.7"

active_record_version = ENV.fetch("ACTIVE_RECORD_VERSION", "~> 4")

gem "activerecord", active_record_version
gem "activesupport", active_record_version

if active_record_version == "~> 4"
  gem "pg", "~> 0.15"
else
  gem "pg"
end

# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in wt_activerecord_index_spy.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "rubocop", "~> 1.7"

gem 'activerecord', ENV.fetch('ACTIVE_RECORD_VERSION')
gem 'activesupport', ENV.fetch('ACTIVE_RECORD_VERSION')

if ENV.fetch('ACTIVE_RECORD_VERSION') == '~> 4'
  gem "pg", "~> 0.15"
else
  gem "pg"
end

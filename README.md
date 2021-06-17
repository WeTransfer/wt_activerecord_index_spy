# wt_activerecord_index_spy

[![Gem](https://img.shields.io/gem/v/wt_activerecord_index_spy)](https://rubygems.org/gems/wt_activerecord_index_spy)
![GitHub Actions Workflow](https://github.com/WeTransfer/wt_activerecord_index_spy/actions/workflows/main.yml/badge.svg)
[![Hippocratic License](https://img.shields.io/badge/license-Hippocratic-green)](https://github.com/WeTransfer/wt_activerecord_index_spy/blob/main/LICENSE.md)

A Ruby library to watch and analyze queries that run using `ActiveRecord` to check
if they use a proper index.

It subscribes to `sql.active_record` notification using `ActiveSupport::Notifications`.

It was designed to be used in tests, but it's also possible to use it in
staging or production, carefully.

## Why would I use this?

Imagine you have an application running in production and after a deploy, it starts to slow down.

After a perhaps exhaustive debugging session, you may find that a new query or perhaps a change
in the database schema was responsible for starting to have queries that do not use database indexes.

Then, you create the appropriate index and the problem is solved!

By using this gem, you can get those queries that are not using suitable database indexes in
your test suite. So you won't have surprises like the example above, after a deploy.

You can also enable the gem in your development/staging environment, generate a report
and analyze if there is any missing index.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wt_activerecord_index_spy'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install wt_activerecord_index_spy

## Usage

There are 3 different modes to use it:

### 1 - Using a test matcher

Include the helper in your RSpec configuration:

```ruby
require 'wt_activerecord_index_spy/test_helpers'

RSpec.configure do |config|
  config.include(WtActiverecordIndexSpy::TestHelpers)
end
```

Use the helper `have_used_db_indexes` where you want to check if all queries used database indexes:

```ruby
it 'uses an index for all the queries' do
  expect { SomeClass.some_method }.to have_used_db_indexes
end
```

Given that some results are uncertain, it's also possible to set the matcher to fail only with certain results:

```ruby
it 'uses an index for all the queries' do
  expect { SomeClass.some_method }.to have_used_db_indexes(only_certains: true)
end
```

#### Run for all rspec tests

By adding the following to your `rspec` configuration the `have_used_db_indexes` will run on each individual test and error if an index has not been used:

```ruby
Rspec.configure do |config|
  config.around(:each) do |example|
    unless example.metadata[:skip_index_spy]
      expect { example.run }.to(have_used_db_indexes)
    else
      example.run
    end
  end

  config.after(:all) do
    WtActiverecordIndexSpy.export_html_results
  end
end
```

If you wish to skip index checking for specific tests you can then annotate your test as follows:

```ruby
describe 'Will not check indexes', :skip_index_spy do
# ...or...
context 'Does not check indexes', :skip_index_spy do
# ...or...
it 'will not check indexes', :skip_index_spy do
```

### 2 - Watching all queries from a start point

Add this line to enable it:

```ruby
WtActiverecordIndexSpy.watch_queries
```

After that, `wt_activerecord_index_spy` will run an `EXPLAIN` query for every query
fired with `ActiveRecord` that has a `WHERE` condition.

Finally, you can generate a report with the results:

```ruby
WtActiverecordIndexSpy.export_html_results
```

This method creates an HTML file with a report and prints its location to STDOUT.

The content of this file is similar to this:

| Level | Identifier | Query | Origin |
| ----  | ---------- | ----- | ------ |
| certain | User Load | SELECT `users`.* FROM `users` WHERE `users`.`name` = 'lala' LIMIT 1  | spec/wt_activerecord_index_spy_spec.rb:162 |
| uncertain | User Load | SELECT `users`.* FROM `users` WHERE `users`.`city_id` IN (SELECT `cities`.`id` FROM `cities` WHERE `cities`.`name` = 'Santo Andre') | spec/wt_activerecord_index_spy_spec.rb:173 |

Where:
- **Level**: `certain` when it is certain that an index is missing, or `uncertain` when it's not possible to be sure
- **Identifier**: is the query identifier reported `ActiveRecord` notification
- **Origin**: is the line the query was fired

This mode, by default, **ignores** queries that were originated in test code. For that, it considers files which path includes `test/` or `spec/`.

It's possible to disable it as follows:

```ruby
WtActiverecordIndexSpy.watch_queries(ignore_queries_originated_in_test_code: false)
```

If the same query runs in many places, only one origin will be added to the report.

It's also possible to get the results using the following methods:

```ruby
# Returns a list of certain results
WtActiverecordIndexSpy.certain_results

# Returns a list of certain and uncertain results mixed
WtActiverecordIndexSpy.results
```

### 3 - Watching all queries given a block

It's also possible to enable it in a specific context, using a block:

```ruby
WtActiverecordIndexSpy.watch_queries do
  # some code...
end
```

After that, you can generate the HTML report with:

```ruby
WtActiverecordIndexSpy.export_html_results
```

## Supported versions

Currently, it supports:

**Ruby**: 2.7, 2.6, 2.5

**Mysql**: 5.7

**PostgreSQL**: 13.2

Note: Currently, the PostgreSQL query analyser is not so intelligent and can't be
certain if an index is missing or not. So all results are `uncertain`. More
details in https://github.com/WeTransfer/wt_activerecord_index_spy/issues/12

**ActiveRecord**: 6, 5, 4

**RSpec**: 3.x

## Development

After checking out the repo, run `cp .env.template .env` and set database credentials to run the tests.

Run `bin/setup` to install dependencies.

Then, run `bundle exec rake db:create db:migrate` to create the Mysql databases and `ADAPTER=postgresql bundle exec rake db:create db:migrate` to create the PostgresSQL database.

Then, run `bundle exec rspec` to run the tests for Mysql and `ADAPTER=postgresql bundle exec rspec`.

You can also run `bundle exec bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wetransfer/wt_activerecord_index_spy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](./CODE_OF_CONDUCT.md).
Please add your name to the [CONTRIBUTORS.md](./CONTRIBUTORS.md)

## License

The gem is available as open source under the terms of the [Hippocratic License](https://firstdonoharm.dev/version/2/1/license.html).

## Code of Conduct

Everyone interacting in the WT Activerecord Index Spy project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](./CODE_OF_CONDUCT.md).

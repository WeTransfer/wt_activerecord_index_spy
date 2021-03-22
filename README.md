# wt_activerecord_index_spy

A Ruby library to watch and analyze queries that run using `ActiveRecord` to check
if they use a proper index.

It subscribes to `sql.active_record` notification using `ActiveSupport::Notifications`.

It was designed to be used in tests, but it's also possible to use it in
staging or production, carefully.

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

There are 2 different modes to use it:

### 1 - Using a test matcher

Include the helper in your RSpec configuration:

```ruby
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

### 2 - Watching all queries from a start point

Add this line to enable it:

```ruby
WtActiverecordIndexSpy.watch_queries
```

After that, `wt_activerecord_index_spy` will run an `EXPLAIN` query for every query
fired with `ActiveRecord` that has a `WHERE` condition.

After that, you can generate a report with the results:

```ruby
WtActiverecordIndexSpy.export_html_results
```

Which creates a table similar to this:

| Level | Identifier | Query | Origin |
| ----  | ---------- | ----- | ------ |
| certain | User Load | SELECT `users`.* FROM `users` WHERE `users`.`name` = 'lala' LIMIT 1  | spec/wt_activerecord_index_spy_spec.rb:162 |
| uncertain | User Load | SELECT `users`.* FROM `users` WHERE `users`.`city_id` IN (SELECT `cities`.`id` FROM `cities` WHERE `cities`.`name` = 'Santo Andre') | spec/wt_activerecord_index_spy_spec.rb:173 |

Where:
- **Level**: `certain` when an index is certain to be missing, or `uncertain` when it's not possible to be sure
- **Identifier**: is the query identifier reported `ActiveRecord` notification
- **Origin**: is the line the query was fired

This mode, by default, **ignores** queries that were originated in test code. For that, it looks for files which name includes `_test` or `_spec`.

It's possible to disable it as follows:

```ruby
WtActiverecordIndexSpy.watch_queries(ignore_queries_originated_in_test_code: false)
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

Currently, it supports only specific versions of Ruby, ActiveRecord and MySql:

**Ruby**: 2.7, 2.6

**Mysql**: 5.7

**ActiveRecord**: 6.1

**RSpec**: 3.x

## Development

After checking out the repo, run `cp .env.template .env` and set database credentials to run the tests.

Run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Before running the tests, it's required to create the test database:

```bash
bundle exec rake db:create db:migrate
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/wt_activerecord_index_spy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/wt_activerecord_index_spy/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the WtActiverecordIndexSpy project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/wt_activerecord_index_spy/blob/main/CODE_OF_CONDUCT.md).

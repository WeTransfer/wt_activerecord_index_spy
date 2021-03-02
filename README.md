# wt_activerecord_index_spy

A Ruby library to watch and analyze queries that run using `ActiveRecord` to check
if they use a proper index.

It subscribes to `sql.active_record` notification using `ActiveSupport::Notifications`.

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

Add this line to enable it:

```ruby
WtActiverecordIndexSpy.watch_queries
```

After that, `wt_activerecord_index_spy` will run an `EXPLAIN` query for every query
fired with `ActiveRecord` that has a `WHERE` condition.

It's also possible to enable it in a specific context, using a block:

```ruby
WtActiverecordIndexSpy.watch_queries do
  # some code...
end
```

After that, you can generate a report with the results:

```ruby
WtActiverecordIndexSpy.export_html_results
```

Which creates a table similar to this:

| Level | Identifier | Query | Origin |
| ----  | ---------- | ----- | ------ |
| critical | User Load | SELECT `users`.* FROM `users` WHERE `users`.`name` = 'lala' LIMIT 1  | spec/wt_activerecord_index_spy_spec.rb:162 |
| warning | User Load | SELECT `users`.* FROM `users` WHERE `users`.`city_id` IN (SELECT `cities`.`id` FROM `cities` WHERE `cities`.`name` = 'Santo Andre') | spec/wt_activerecord_index_spy_spec.rb:173 |

Where:
- **Level**: `critical` when an index is certain to be missing, or `warning` when it's not possible to be sure
- **Identifier**: is the query identifier reported `ActiveRecord` notification
- **Origin**: is the line the query was fired. By default it ignores queries fired in test code. It's possible to change it setting `WtActiverecordIndexSpy.ignore_queries_originated_in_test_code = false`

## Supported versions

Currently, it supports only specific versions of Ruby, ActiveRecord and MySql:

**Ruby**: 2.7, 2.6

**Mysql**: 5.7

**ActiveRecord**: 6.1

## Development

After checking out the repo, run `cp .env.template .env` and set database credentials to run the tests.

Run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/wt_activerecord_index_spy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/wt_activerecord_index_spy/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the WtActiverecordIndexSpy project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/wt_activerecord_index_spy/blob/main/CODE_OF_CONDUCT.md).

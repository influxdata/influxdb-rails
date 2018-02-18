> You are looking at the README for the master branch of this gem.
> The latest released version lives in the stable-04 branch,
> [see here](https://github.com/influxdata/influxdb-rails/tree/stable-04#readme)
> for an online version.

# influxdb-rails

[![Gem Version](https://badge.fury.io/rb/influxdb-rails.svg)](https://badge.fury.io/rb/influxdb-rails)
[![Build Status](https://travis-ci.org/influxdata/influxdb-rails.svg?branch=master)](https://travis-ci.org/influxdata/influxdb-rails)

Automatically instrument your Ruby on Rails applications and write the
metrics directly into [InfluxDB](http://influxdb.org/).

This gem is designed for Rails 4.0+, Ruby 2.2+ and InfluxDB 0.9+.

## Install

```
$ [sudo] gem install influxdb-rails
```

Or add it to your `Gemfile`, etc.

## Usage

To get things set up, just create an initializer:

```
$ cd /to/you/rails/application
$ touch config/initializers/influxdb-rails.rb
```

In this file, you can configure the `InfluxDB::Rails` adapter. The default
config should look something like this:

``` ruby
InfluxDB::Rails.configure do |config|
  config.influxdb_database = "rails"
  config.influxdb_username = "root"
  config.influxdb_password = "root"
  config.influxdb_hosts    = ["localhost"]
  config.influxdb_port     = 8086

  # config.retry = false
  # config.async = false
  # config.open_timeout = 5
  # config.read_timeout = 30
  # config.max_delay = 300
  # config.time_precision = 'ms'

  # config.series_name_for_controller_runtimes = "rails.controller"
  # config.series_name_for_view_runtimes       = "rails.view"
  # config.series_name_for_db_runtimes         = "rails.db"
  # config.series_name_for_exceptions          = "rails.exceptions"
  # config.series_name_for_instrumentation     = "instrumentation"

  # Set the application name to something meaningful, by default we
  # infer the app name from the Rails.application class name.
  # config.application_name = Rails.application.class.parent_name
end
```

To see all default values, take a look into `InfluxDB::Rails::Configuration::DEFAULTS`,
defined in `lib/influxdb/rails/configuration.rb`

Out of the box, you'll automatically get reporting of your controller,
view, and db runtimes for each request. You can also call through to the
underlying `InfluxDB::Client` object to write arbitrary data like this:

``` ruby
InfluxDB::Rails.client.write_point "events",
  tags:   { url: "/foo", user_id: current_user.id },
  values: { value: 0 }
```

Additional documentation for `InfluxDB::Client` lives in the
[influxdb-ruby](http://github.com/influxdata/influxdb-ruby) repo.

## Testing

```
git clone git@github.com:influxdata/influxdb-rails.git
cd influxdb-rails
bundle
bundle exec rake
```

## Contributing

- Fork this repository on GitHub.
- Make your changes.
  - Add tests.
  - Add an entry in the `CHANGELOG.md` in the "unreleased" section on top.
- Run the tests:
  - Either run them manually:
    ```sh
    for gemfile in gemfiles/Gemfile.rails-*.x; do     \
      BUNDLE_GEMFILE=$gemfile bundle install --quiet; \
      BUNDLE_GEMFILE=$gemfile bundle exec rspec;      \
    done
    ```
  - or wait for [Travis][travis-pr] to pick up your changes, *after*
    you made a pull request.
- Send a pull request.
  - Please rebase against the master branch.
- If your changes look good, we'll merge them.

[travis-pr]: https://travis-ci.org/influxdata/influxdb-rails/pull_requests

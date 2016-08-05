influxdb-rails
==============

> This library is now updated to require `influxdb-ruby` v0.2.0 and greater, meaning that only InfluxDB v0.9.x and higher will be supported. **If you want to use this library with InfluxDB v0.8.x, you'll need to use v0.1.10 or earlier. You will also need to manually specify `gem 'influxdb', '0.1.9'` in your gemfile.**

We encourage you to submit a pull request if you have a contribution. Maintained by [@toddboom](https://github.com/toddboom).

----------



[![Build Status](https://travis-ci.org/influxdb/influxdb-rails.png?branch=master)](https://travis-ci.org/influxdb/influxdb-rails)

Auotmatically instrument your Ruby on Rails applications and write the metrics directly into [InfluxDB](http://influxdb.org/).

Install
-------

```
$ [sudo] gem install influxdb-rails
```

Or add it to your `Gemfile`, etc.

Usage
-----

To get things set up, just create an initializer:

```
$ rails g influxdb
```

Then, you can edit the file at `config/initializers/influxdb-rails.rb`. The default config should look something like this:

``` ruby
InfluxDB::Rails.configure do |config|
  config.influxdb_database = "rails"
  config.influxdb_username = "root"
  config.influxdb_password = "root"
  config.influxdb_hosts    = ["localhost"]
  config.influxdb_port     = 8086

  # config.series_name_for_controller_runtimes = "rails.controller"
  # config.series_name_for_view_runtimes       = "rails.view"
  # config.series_name_for_db_runtimes         = "rails.db"
end
```

Out of the box, you'll automatically get reporting of your controller, view, and db runtimes for each request. You can also call through to the underlying `InfluxDB::Client` object to write arbitrary data like this:

``` ruby
InfluxDB::Rails.client.write_point("events", { values: { value: 0 }, tags: { url: "/foo", user_id: current_user.id }})
```

Additional documentation for `InfluxDB::Client` lives in the [influxdb-ruby](http://github.com/influxdb/influxdb-ruby) repo.

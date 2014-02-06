influxdb-ruby
=============

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

Create a barebones initializer:

```
$ rails g influxdb
```

Then, you can edit the file at `config/initializers/influxdb-rails.rb`. The default config should look like this:

``` ruby
InfluxDB::Rails.configure do |config|
  config.influxdb_database = "rails"
  config.influxdb_username = "root"
  config.influxdb_password = "root"
  config.influxdb_host     = "localhost"
  config.influxdb_port     = 8086
end
```

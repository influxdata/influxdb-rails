> You are looking at the README for the master branch of this gem.
> The latest released version lives in the stable-04 branch,
> [see here](https://github.com/influxdata/influxdb-rails/tree/stable-04#readme)
> for an online version.

# influxdb-rails

[![Gem Version](https://badge.fury.io/rb/influxdb-rails.svg)](https://badge.fury.io/rb/influxdb-rails)
[![Build Status](https://travis-ci.org/influxdata/influxdb-rails.svg?branch=master)](https://travis-ci.org/influxdata/influxdb-rails)

Automatically instrument your Ruby on Rails applications and write the
metrics directly into [InfluxDB](http://influxdb.org/).

This gem is designed for Rails 4.2+, Ruby 2.3+ and InfluxDB 0.9+.


## Installation

Add the gem to your `Gemfile`:

```console
$ echo 'gem "influxdb-rails"' >>Gemfile
$ bundle install
```

## Usage

To get things set up, just create an initializer:

```console
$ bundle exec rails generate influxdb
```

This creates a file `config/initializers/influxdb_rails.rb`, which allows
configuration of this gem.

The only setting you actually need to update is the name of the database
within the InfluxDB server instance (also don't forget to create this
database as well):

```ruby
InfluxDB::Rails.configure do |config|
  config.client.database = "rails"
end
```

You'll find *most* of the config settings in the initializer file. The
canonical list of default values is located in `lib/influxdb/rails/configuration.rb`
(`InfluxDB::Rails::Configuration::DEFAULTS`).

### Reporting options

Out of the box, you'll automatically get reporting of your controller, view,
and db runtimes and rendering of template, partial and collection for each
request:

```ruby
InfluxDB::Rails.configure do |config|
  config.report_controller_runtimes = true
  config.report_view_runtimes       = true
  config.report_render_template     = true
  config.report_render_partial      = true
  config.report_render_collection   = true
  config.report_db_runtimes         = true
  config.report_sql                 = false
  config.report_exceptions          = true
  config.report_instrumentation     = true
end
```

Reporting of SQL queries is disabled by default, because it's still considered
experimantal: It relies on String parsing which might cause performance
issues on query intensive applications.

### InfluxDB client

The settings named `config.client.*` are used to construct an `InfluxDB::Client`
instance, which is used internally to transmit the reporting datapoints
to your InfluxDB server. You can access this client as well, and perform
arbitrary operations on your data:

```ruby
InfluxDB::Rails.client.write_point "events",
  tags:   { url: "/foo", user_id: current_user.id, location: InfluxDB::Rails.current.location },
  values: { value: 0 }
```

If you do that, it might be usefull to add the current context to these custom
data points which can get accessed with `InfluxDB::Rails.current.location`.

See [influxdb-ruby](http://github.com/influxdata/influxdb-ruby) for a
full list of config options and detailed usage.

### Tags

You can modify the tags sent to InfluxDB by defining a middleware, which
receives the current tag set as argument and returns a hash in the same
form. The middleware can be any object, as long it responds to `#call`
(like a `Proc`):

```ruby
InfluxDB::Rails.configure do |config|
  config.tags_middleware = lambda do |tags|
    tags.merge(env: Rails.env)
  end
end
```

The `tags` argument is a Hash (mapping Symbol keys to String values). The
actual keys and values depend on the series name (`tags[:series]`, see
next section).

If you want to add dynamically tags or fields *per request*, you can access
`InfluxDB::Rails.current` to do so. For instance, you could add the current
user as tag and the request id to every data point:

```ruby
class ApplicationController
  before_action :set_influx_data

  def set_influx_data
    InfluxDB::Rails.current.tags = { user: current_user.id }
    InfluxDB::Rails.current.values = { id: request.request_id }
  end
end
```

#### Default values

> N.B. this list might not be exhaustive. If you encounter a discrepance,
> please [open an issue](https://github.com/influxdata/influxdb-rails/issus/new).

By default, the following tags are sent for requests (`report_requests`):

```ruby
{
  method:      "#{payload[:controller]}##{payload[:action]}",
  server:      Socket.gethostname,
  app_name:    configuration.application_name,
  http_method: payload[:method],
  format:      payload[:format],
  status:      payload[:status]
}
```

For the render series (`report_render_template`, `report_render_partial`,
and `report_render_collection`):

```ruby
  server:     Socket.gethostname,
  app_name:   configuration.application_name,
  location:   "#{payload[:controller]}##{payload[:action]}",
  filename:   payload[:identifier],
  count:      payload[:count],
  cache_hits: payload[:cache_hits],
```

For the SQL series (`report_sql`, disabled by default)

```ruby
  server:     Socket.gethostname,
  app_name:   configuration.application_name,
  location:   "#{payload[:controller]}##{payload[:action]}",,
  operation:  "SELECT",
  class_name: "USER",
  name:       payload[:name],
```

For more information about the payload, have a look at the
[official ActiveSupport documentation][1].

[1]: https://guides.rubyonrails.org/active_support_instrumentation.html#process-action-action-controller

For the exceptions (`report_exceptions`):

```ruby
{
  application_name:   InfluxDB::Rails.configuration.application_name,
  application_root:   InfluxDB::Rails.configuration.application_root,
  framework:          InfluxDB::Rails.configuration.framework,
  framework_version:  InfluxDB::Rails.configuration.framework_version,
  language:           "Ruby",
  language_version:   "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}",
  custom_data:        @custom_data,
  class:              @exception.class.to_s,
  method:             "#{@controller}##{@action}",
  filename:           File.basename(@backtrace.lines.first.try(:file)),
  server:             Socket.gethostname,
  status:             "open",
}
```


## Frequently Asked Questions

### I'm seeing far less requests recorded in InfluxDB than my logs suggest.

By default, this gem writes data points with *millisecond time precision*
to the InfluxDB server. If you have more than 1000 requests/second (and/or
multiple parallel requests), **only the last** data point (within the
same tag set) is stored. See [InfluxDB server docs][duplicate-points] for
further details.

To work around this limitation, set the `config.client.time_precision`
to one of `"us"` (microseconds, 1·10<sup>-6</sup>s) or `"ns"` (nanoseconds,
1·10<sup>-9</sup>s).

Please note: This will only ever reduce the likelyhood of data points
overwriting each other, but not eliminate it completely.

[duplicate-points]: https://docs.influxdata.com/influxdb/v1.4/troubleshooting/frequently-asked-questions/#how-does-influxdb-handle-duplicate-points


### How does the measurement influence the response time?

This gem subscribes to various `ActiveSupport::Notifications` hooks.
(cf. [guide][arn-guide] · [docs][arn-docs] · [impl][arn-impl]). The
controller notifications are run *after* a controller action has finished,
and should not impact the response time.

Other notification hooks (mainly for rendering templates and, if enabled,
SQL queries) run *inline* in the request processing. The amount of overhead
introduced should be negligible, though.

By default, this gem performs writes to InfluxDB asynchronously. A single
hooks usually only performs some time delta calculations, and then enqueues
the data point into a worker queue (which is processed by a background
thread).

If you, however, use a synchronous client (`config.client.async = false`),
the data points are immediately sent to the InfluxDB server. Depending on
the network link, this might cause the HTTP thread to block a lot longer.

[arn-guide]: http://guides.rubyonrails.org/v5.1/active_support_instrumentation.html#process-action-action-controller
[arn-docs]: http://api.rubyonrails.org/v5.1/classes/ActiveSupport/Notifications.html
[arn-impl]: https://github.com/rails/rails/blob/5-1-stable/actionpack/lib/action_controller/metal/instrumentation.rb#L30-L38


### How does this gem handle an unreachable InfluxDB server?

By default, the InfluxDB client will retry indefinetly, until a write
succeedes (see [client docs][] for details). This has two important
implcations, depending on the value of `config.client.async`:

- if the client runs asynchronously (i.e. in a seperate thread), the queue
  might fill up with hundrets of megabytes of data points
- if the client runs synchronously (i.e. inline in the request/response
  cycle), it might block all available request threads

In both cases, your application server might become inresponsive and needs
to be restarted (which can happen automatically in `cgroups` contexts,
like Docker containers).

If you setup a maximum retry value (`Integer === config.client.retry`),
the client will try upto that amount of times to send the data to the server
and (on final error) log an error and discard the values.

[client docs]: https://github.com/influxdata/influxdb-ruby#retry


### What happens with unwritten points, when the application restarts?

The data points are simply discarded.


### What happens, when the InfluxDB client or this gem throws an exception? Will the user see 500 errors?

No. The controller instrumentation is wrapped in a `rescue StandardError`
clause, i.e. this gem will only write the error to the `client.logger`
(`Rails.logger` by default) and not disturb the user experience.


## Testing

```console
$ git clone git@github.com:influxdata/influxdb-rails.git
$ cd influxdb-rails
$ bundle install
$ rake            # unit tests + Rubocop linting
$ rake spec       # only unit tests
$ rake rubocop    # only Rubocop linter
$ rake test:all   # integration tests with various Rails version
```

## Contributing

- Fork this repository on GitHub.
- Make your changes.
  - Add tests.
  - Add an entry in the `CHANGELOG.md` in the "unreleased" section on top.
- Run the tests:
  - Either run them manually:
    ```console
    $ rake test:all
    ```
  - or wait for [Travis][travis-pr] to pick up your changes, *after*
    you made a pull request.
- Send a pull request.
- If your changes are looking good, we'll merge them.

[travis-pr]: https://travis-ci.org/influxdata/influxdb-rails/pull_requests

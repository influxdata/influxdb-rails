InfluxDB::Rails.configure do |config|
  ## The only settings you actually need to set are org, bucket and token.
  config.client.bucket = "bucket"
  config.client.org = "org"
  config.client.token = "token"
  # config.client.url = "localhost:8086",

  ## Various other client and connection options. These are used to create
  ## an `InfluxDB2::Client` instance (i.e. `InfluxDB::Rails.client`).
  ##
  ## See docs for the influxdb-client gem for the canonical list of options:
  ## https://github.com/influxdata/influxdb-client-ruby#creating-a-client
  ##
  # config.client.use_ssql = true
  # config.client.open_timeout = 5.seconds
  # config.client.write_timeout = 5.seconds
  # config.client.read_timeout = 60.seconds
  # config.client.time_precisions = InfluxDB2::WritePrecision::MILLISECOND
  # config.client.retries = 0
  # config.client.max_retry_delay_ms = 10_000
  # config.client.async = true

  ## Disable rails framework hooks.
  # config.ignored_hooks = ['sql.active_record', 'render_template.action_view']

  # Modify tags on the fly.
  # config.tags_middleware = ->(tags) { tags }

  ## Set the application name to something meaningful, by default we
  ## infer the app name from the Rails.application class name.
  # config.application_name = Rails.application.class.parent_name
end

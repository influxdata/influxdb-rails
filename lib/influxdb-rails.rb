require "net/http"
require "net/https"
require "rubygems"
require "socket"
require "influxdb-client"
require "influxdb/rails/middleware/block_instrumentation_subscriber"
require "influxdb/rails/middleware/render_subscriber"
require "influxdb/rails/middleware/request_subscriber"
require "influxdb/rails/middleware/sql_subscriber"
require "influxdb/rails/middleware/active_record_subscriber"
require "influxdb/rails/middleware/active_job_subscriber"
require "influxdb/rails/middleware/action_mailer_subscriber"
require "influxdb/rails/sql/query"
require "influxdb/rails/version"
require "influxdb/rails/configuration"
require "influxdb/rails/context"

require "influxdb/rails/railtie" if defined?(Rails::Railtie)

module InfluxDB
  # InfluxDB::Rails contains the glue code needed to integrate with
  # InfluxDB and Rails. This is a singleton class.
  module Rails
    class << self
      attr_writer :configuration, :client, :write_api, :logger

      def configure
        yield configuration if block_given?

        # if we change configuration, reload the client
        self.client = nil
        self.write_api = nil
        self.logger = nil

        configuration
      end

      def configuration
        @configuration ||= InfluxDB::Rails::Configuration.new
      end

      # rubocop:disable Metrics/MethodLength

      def client
        @client ||= begin
          cfg = configuration.client
          InfluxDB2::Client.new(
            cfg.url,
            cfg.token,
            org:           cfg.org,
            bucket:        cfg.bucket,
            precision:     cfg.precision,
            open_timeout:  cfg.open_timeout,
            write_timeout: cfg.write_timeout,
            read_timeout:  cfg.read_timeout,
            use_ssl:       cfg.use_ssl,
            logger:        logger,
            async:         cfg.async,
            retries:       cfg.retries
          )
        end
      end

      # rubocop:enable Metrics/MethodLength

      def write_api
        @write_api ||= client.create_write_api(write_options: configuration.client.write_options)
      end

      def logger
        @logger ||= configuration.logger
      end

      def current
        @current ||= InfluxDB::Rails::Context.new
      end

      def instrument(name, options = {})
        ActiveSupport::Notifications.instrument "block_instrumentation.influxdb_rails",
                                                **options.merge(name: name) do
          yield if block_given?
        end
      end
    end
  end
end

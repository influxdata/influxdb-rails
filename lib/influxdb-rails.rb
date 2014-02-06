require "net/http"
require "net/https"
require "rubygems"
require "socket"
require "thread"

require "influxdb/rails/version"
require "influxdb/rails/logger"
require "influxdb/rails/exception_presenter"
require "influxdb/rails/configuration"
require "influxdb/rails/backtrace"
require "influxdb/rails/rack"

require "influxdb/rails/railtie" if defined?(Rails::Railtie)

module InfluxDB
  module Rails
    class << self
      include InfluxDB::Rails::Logger

      attr_writer :configuration
      attr_accessor :client

      def configure(silent = false)
        yield(configuration)
        self.client = InfluxDB::Client.new configuration.influxdb_database,
          :username => configuration.influxdb_username,
          :password => configuration.influxdb_password,
          :host => configuration.influxdb_host,
          :port => configuration.influxdb_port
      end

      def configuration
        @configuration ||= InfluxDB::Rails::Configuration.new
      end

      def report_exception_unless_ignorable(e, env = {})
        report_exception(e, env) unless ignorable_exception?(e)
      end
      alias_method :transmit_unless_ignorable, :report_exception_unless_ignorable

      def report_exception(e, env = {})
        begin
          env = influxdb_request_data if env.empty? && defined? influxdb_request_data
          exception_presenter = ExceptionPresenter.new(e, env)
          log :info, "Exception: #{exception_presenter.to_json[0..512]}..."

          InfluxDB::Rails.client.write_point "rails.exceptions",
            :context => exception_presenter.context,
            :dimensions => exception_presenter.dimensions

        rescue => e
          log :info, "[InfluxDB] Something went terribly wrong. Exception failed to take off! #{e.class}: #{e.message}"
        end
      end
      alias_method :transmit, :report_exception

      def current_timestamp
        Time.now.utc.to_i
      end

      def ignorable_exception?(e)
        configuration.ignore_current_environment? ||
        !!configuration.ignored_exception_messages.find{ |msg| /.*#{msg}.*/ =~ e.message  } ||
        configuration.ignored_exceptions.include?(e.class.to_s)
      end

      def rescue(&block)
        block.call
      rescue StandardError => e
        if configuration.ignore_current_environment?
          raise(e)
        else
          transmit_unless_ignorable(e)
        end
      end

      def rescue_and_reraise(&block)
        block.call
      rescue StandardError => e
        transmit_unless_ignorable(e)
        raise(e)
      end
    end
  end
end

require "influxdb/rails/values"
require "influxdb/rails/tags"

module InfluxDB
  module Rails
    class Metric
      def initialize(configuration:, timestamp:, tags: {}, values: {}, hook_name:)
        @configuration = configuration
        @timestamp = timestamp
        @tags = tags
        @values = values
        @hook_name = hook_name
      end

      def write
        return unless enabled?

        client.write_point configuration.measurement_name, options
      rescue StandardError => e
        ::Rails.logger.error("[InfluxDB::Rails] Unable to write points: #{e.message}")
      end

      private

      attr_reader :configuration, :tags, :values, :timestamp, :hook_name

      def options
        {
          values:    Values.new(values: values).to_h,
          tags:      Tags.new(tags: tags, config: configuration).to_h,
          timestamp: timestamp_with_precision,
        }
      end

      def timestamp_with_precision
        InfluxDB.convert_timestamp(timestamp.utc, configuration.client.time_precision)
      end

      def enabled?
        !configuration.ignore_current_environment? &&
          !configuration.ignored_hooks.include?(hook_name)
      end

      def client
        InfluxDB::Rails.client
      end
    end
  end
end

require "influxdb/rails/timestamp_conversion"
require "influxdb/rails/logger"

module InfluxDB
  module Rails
    module Middleware
      class RenderSubscriber
        include InfluxDB::Rails::TimestampConversion
        include InfluxDB::Rails::Logger

        attr_reader :series_name, :config

        def initialize(config, series_name)
          @config = config
          @series_name = series_name
        end

        def call(_name, started, finished, _unique_id, payload)
          return if !config.instrumentation_enabled? ||
                    config.ignore_current_environment?

          value = ((finished - started) * 1000).ceil
          ts = convert_timestamp(finished.utc, config.time_precision)
          begin
            InfluxDB::Rails.client.write_point series_name, values: { value: value }, tags: tags(payload), timestamp: ts
          rescue StandardError => e
            log :error, "[InfluxDB::Rails] Unable to write points: #{e.message}"
          end
        end

        private

        def tags(payload)
          {
            filename:   payload[:identifier],
            count:      payload[:count],
            cache_hits: payload[:cache_hits],
          }.reject { |_, value| value.nil? }
        end
      end
    end
  end
end

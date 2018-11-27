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
          tags = {
            file_name: payload[:identifier],
          }
          ts = convert_timestamp(finished.utc, config.time_precision)
          begin
            InfluxDB::Rails.client.write_point series_name, values: { value: value }, tags: tags, timestamp: ts
          rescue StandardError => e
            log :error, "[InfluxDB::Rails] Unable to write points: #{e.message}"
          end
        end
      end
    end
  end
end

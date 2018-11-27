require "influxdb/rails/timestamp_conversion"
require "influxdb/rails/logger"

module InfluxDB
  module Rails
    module Middleware
      class RequestSubscriber
        include InfluxDB::Rails::TimestampConversion
        include InfluxDB::Rails::Logger

        attr_reader :configuration

        def initialize(configuration)
          @configuration = configuration
        end

        def call(_name, start, finish, _id, payload)
          return if !configuration.instrumentation_enabled? ||
                    configuration.ignore_current_environment?

          begin
            series(payload, start, finish).each do |series_name, value|
              InfluxDB::Rails.client.write_point series_name, values: { value: value }, tags: tags(payload), timestamp: convert_timestamp(finish.utc, configuration.time_precision)
            end
          rescue StandardError => e
            log :error, "[InfluxDB::Rails] Unable to write points: #{e.message}"
          end
        end

        private

        def series(payload, start, finish)
          {
            configuration.series_name_for_controller_runtimes => ((finish - start) * 1000).ceil,
            configuration.series_name_for_view_runtimes       => (payload[:view_runtime] || 0).ceil,
            configuration.series_name_for_db_runtimes         => (payload[:db_runtime] || 0).ceil,
          }
        end

        def tags(payload)
          configuration.tags_middleware.call(
            {
              method:      "#{payload[:controller]}##{payload[:action]}",
              status:      payload[:status],
              format:      payload[:format],
              http_method: payload[:method],
              server:      Socket.gethostname,
              app_name:    configuration.application_name,
            }.reject { |_, value| value.nil? })
        end
      end
    end
  end
end

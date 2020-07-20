require "influxdb/rails/middleware/subscriber"

module InfluxDB
  module Rails
    module Middleware
      class RequestSubscriber < Subscriber # :nodoc:
        def write
          super
        ensure
          InfluxDB::Rails.current.reset
        end

        private

        def tags
          {
            method:      "#{payload[:controller]}##{payload[:action]}",
            hook:        "process_action",
            status:      payload[:status],
            format:      payload[:format],
            http_method: payload[:method],
          }
        end

        def values
          {
            controller: duration,
            view:       (payload[:view_runtime] || 0).ceil,
            db:         (payload[:db_runtime] || 0).ceil,
            started:    started,
          }
        end

        def started
          InfluxDB.convert_timestamp(
            start.utc,
            configuration.client.time_precision
          )
        end
      end
    end
  end
end

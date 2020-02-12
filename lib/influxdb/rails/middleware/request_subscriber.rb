require "influxdb/rails/middleware/subscriber"

module InfluxDB
  module Rails
    module Middleware
      class RequestSubscriber < Subscriber # :nodoc:
        def call(_name, started, finished, _unique_id, payload)
          super
        ensure
          InfluxDB::Rails.current.reset
        end

        private

        def tags(payload)
          {
            method:      "#{payload[:controller]}##{payload[:action]}",
            hook:        "process_action",
            status:      payload[:status],
            format:      payload[:format],
            http_method: payload[:method],
          }
        end

        def values(started, finished, payload)
          {
            controller: ((finished - started) * 1000).ceil,
            view:       (payload[:view_runtime] || 0).ceil,
            db:         (payload[:db_runtime] || 0).ceil,
            started:    InfluxDB.convert_timestamp(
              started.utc,
              configuration.client.time_precision
            ),
          }
        end
      end
    end
  end
end

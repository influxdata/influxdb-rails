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
            status:      status,
            format:      payload[:format],
            http_method: payload[:method],
            exception:   payload[:exception]&.first,
          }
        end

        def fields
          {
            controller: duration,
            view:       (payload[:view_runtime] || 0).ceil,
            db:         (payload[:db_runtime] || 0).ceil,
            started:    start.utc,
          }
        end

        def started
          InfluxDB.convert_timestamp(
            start.utc,
            configuration.client.time_precision
          )
        end

        def status
          if payload[:exception] && ::Rails::VERSION::MAJOR < 7
            ActionDispatch::ExceptionWrapper.status_code_for_exception(payload[:exception].first)
          else
            payload[:status]
          end
        end
      end
    end
  end
end

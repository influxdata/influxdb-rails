require "influxdb/rails/middleware/subscriber"

module InfluxDB
  module Rails
    module Middleware
      class RequestSubscriber < Subscriber # :nodoc:
        def call(_name, start, finish, _id, payload)
          return unless enabled?

          InfluxDB::Rails.client.write_point \
            series_name,
            values:    values(start, finish, payload),
            tags:      tags(payload),
            timestamp: timestamp(finish)
        rescue StandardError => e
          log :error, "[InfluxDB::Rails] Unable to write points: #{e.message}"
        ensure
          InfluxDB::Rails.current.reset
        end

        private

        def tags(payload)
          tags = {
            method:      "#{payload[:controller]}##{payload[:action]}",
            status:      payload[:status],
            format:      payload[:format],
            http_method: payload[:method],
            server:      Socket.gethostname,
            app_name:    configuration.application_name,
          }
          super(tags)
        end

        def values(started, finished, payload)
          {
            controller: ((finished - started) * 1000).ceil,
            view:       (payload[:view_runtime] || 0).ceil,
            db:         (payload[:db_runtime] || 0).ceil,
          }.merge(InfluxDB::Rails.current.values).reject do |_, value|
            value.nil? || value == ""
          end
        end
      end
    end
  end
end

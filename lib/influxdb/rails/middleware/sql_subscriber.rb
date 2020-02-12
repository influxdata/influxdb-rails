require "influxdb/rails/middleware/subscriber"
require "influxdb/rails/sql/query"

module InfluxDB
  module Rails
    module Middleware
      class SqlSubscriber < Subscriber # :nodoc:
        def call(_name, started, finished, _unique_id, payload)
          super if InfluxDB::Rails::Sql::Query.new(payload).track?
        end

        private

        def values(_start, duration, payload)
          {
            value: duration,
            sql:   InfluxDB::Rails::Sql::Normalizer.new(payload[:sql]).perform,
          }
        end

        def tags(payload)
          query = InfluxDB::Rails::Sql::Query.new(payload)
          {
            hook:       "sql",
            operation:  query.operation,
            class_name: query.class_name,
            name:       query.name,
            location:   :raw,
          }
        end
      end
    end
  end
end

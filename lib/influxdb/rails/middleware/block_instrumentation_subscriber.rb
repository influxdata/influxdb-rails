require "influxdb/rails/middleware/subscriber"

module InfluxDB
  module Rails
    module Middleware
      class BlockInstrumentationSubscriber < Subscriber
        private

        def fields
          {
            value: duration,
          }.merge(payload[:fields].to_h)
        end

        def tags
          {
            hook: "block_instrumentation",
            name: payload[:name],
          }.merge(payload[:tags].to_h)
        end
      end
    end
  end
end

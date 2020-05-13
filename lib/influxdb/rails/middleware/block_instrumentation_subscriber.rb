require "influxdb/rails/middleware/subscriber"

module InfluxDB
  module Rails
    module Middleware
      class BlockInstrumentationSubscriber < Subscriber
        def values(_start, duration, payload)
          {
            value: duration,
          }.merge(payload[:values].to_h)
        end

        def tags(payload)
          {
            hook: "block_instrumentation",
            name: payload[:name],
          }.merge(payload[:tags].to_h)
        end
      end
    end
  end
end

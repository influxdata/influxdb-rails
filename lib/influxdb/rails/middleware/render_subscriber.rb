require "influxdb/rails/middleware/simple_subscriber"

module InfluxDB
  module Rails
    module Middleware
      class RenderSubscriber < SimpleSubscriber # :nodoc:
        private

        def tags(payload)
          {
            location:   location,
            filename:   payload[:identifier],
            count:      payload[:count],
            cache_hits: payload[:cache_hits],
          }.reject { |_, value| value.blank? }
        end
      end
    end
  end
end

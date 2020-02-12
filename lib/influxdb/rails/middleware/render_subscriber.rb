require "influxdb/rails/middleware/subscriber"

module InfluxDB
  module Rails
    module Middleware
      class RenderSubscriber < Subscriber # :nodoc:
        def short_hook_name
          return "render_template" if hook_name.include?("render_template")
          return "render_partial" if hook_name.include?("render_partial")
          return "render_collection" if hook_name.include?("render_collection")
        end

        private

        def values(_start, duration, payload)
          {
            value:      duration,
            count:      payload[:count],
            cache_hits: payload[:cache_hits],
          }
        end

        def tags(payload)
          {
            hook:     short_hook_name,
            filename: payload[:identifier],
          }
        end
      end
    end
  end
end

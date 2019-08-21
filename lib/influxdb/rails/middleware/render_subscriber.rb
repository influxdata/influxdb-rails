require "influxdb/rails/middleware/simple_subscriber"

module InfluxDB
  module Rails
    module Middleware
      class RenderSubscriber < SimpleSubscriber # :nodoc:
        def short_hook_name
          return "render_template" if hook_name.include?("render_template")
          return "render_partial" if hook_name.include?("render_partial")
          return "render_collection" if hook_name.include?("render_collection")
        end

        private

        def values(started, finished, payload)
          super(started, finished, payload).merge(
            count:      payload[:count],
            cache_hits: payload[:cache_hits]
          ).reject { |_, value| value.nil? }
        end

        def tags(payload)
          tags = {
            location: location,
            hook:     short_hook_name,
            filename: payload[:identifier],
          }
          super(tags)
        end
      end
    end
  end
end

require "influxdb/rails/middleware/subscriber"

module InfluxDB
  module Rails
    module Middleware
      class ActiveJobSubscriber < Subscriber # :nodoc:
        private

        def values
          {
            value: value,
          }
        end

        def tags
          {
            hook:  short_hook_name,
            state: job_state,
            job:   job.class.name,
            queue: job.queue_name,
          }
        end

        def job_state
          return "failed" if failed?

          case short_hook_name
          when "enqueue"
            "queued"
          when "perform_start"
            "running"
          when "perform"
            "succeeded"
          end
        end

        def measure_performance?
          short_hook_name == "perform"
        end

        def short_hook_name
          @short_hook_name ||= fetch_short_hook_name
        end

        def fetch_short_hook_name
          return "enqueue" if hook_name.include?("enqueue")
          return "perform_start" if hook_name.include?("perform_start")
          return "perform" if hook_name.include?("perform")
        end

        def job
          @job ||= payload[:job]
        end

        def value
          return duration if measure_performance?

          1
        end

        def failed?
          payload[:exception_object]
        end
      end
    end
  end
end

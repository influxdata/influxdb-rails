require "influxdb/rails/middleware/subscriber"

module InfluxDB
  module Rails
    module Middleware
      class ActiveJobSubscriber < Subscriber # :nodoc:
        def short_hook_name
          return "enqueue" if hook_name.include?("enqueue")
          return "perform_start" if hook_name.include?("perform_start")
          return "perform" if hook_name.include?("perform")
        end

        def job_state(payload)
          return :failed if payload[:exception_object]

          case short_hook_name
          when "enqueue"
            :queued
          when "perform_start"
            :running
          when "perform"
            :succeeded
          end
        end

        private

        def values(_start, duration, _payload)
          value = measure_performace? ? duration : "1"
          {
            value: value,
          }
        end

        def tags(payload)
          {
            hook:  short_hook_name,
            state: job_state(payload),
            job:   payload[:job].class.name,
            queue: payload[:job].queue_name,
          }
        end

        def measure_performance?
          short_hook_name == "perform.active_job"
        end
      end
    end
  end
end

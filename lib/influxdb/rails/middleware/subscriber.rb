require "influxdb/rails/metric"

module InfluxDB
  module Rails
    module Middleware
      # Subscriber acts as base class for different *Subscriber classes,
      # which are intended as ActiveSupport::Notifications.subscribe
      # consumers.
      class Subscriber
        attr_reader :configuration
        attr_reader :hook_name

        def initialize(configuration, hook_name)
          @configuration = configuration
          @hook_name = hook_name
        end

        def call(_name, start, finish, _id, payload)
          InfluxDB::Rails::Metric.new(
            values:        values(start, finish, payload),
            tags:          tags(payload),
            configuration: configuration,
            timestamp:     finish,
            hook_name:     hook_name
          ).write
        end

        private

        def tags(*)
          raise NotImplementedError, "must be implemented in subclass"
        end

        def values(*)
          raise NotImplementedError, "must be implemented in subclass"
        end
      end
    end
  end
end

require "influxdb/rails/logger"

module InfluxDB
  module Rails
    module Middleware
      # Subscriber acts as base class for different *Subscriber classes,
      # which are intended as ActiveSupport::Notifications.subscribe
      # consumers.
      class Subscriber
        include InfluxDB::Rails::Logger

        attr_reader :configuration

        def initialize(configuration)
          @configuration = configuration
        end

        def call(*)
          raise NotImplementedError, "must be implemented in subclass"
        end

        private

        def enabled?
          configuration.instrumentation_enabled? &&
            !configuration.ignore_current_environment?
        end
      end
    end
  end
end

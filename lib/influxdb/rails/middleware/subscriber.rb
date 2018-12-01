require "influxdb/rails/logger"

module InfluxDB
  module Rails
    module Middleware
      class Subscriber
        include InfluxDB::Rails::Logger

        attr_reader :configuration

        def initialize(configuration)
          @configuration = configuration
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

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
      end
    end
  end
end
require 'action_controller'
require 'errplane'
require 'errplane/rails/middleware/hijack_rescue_action_everywhere'
require 'errplane/rails/air_traffic_controller'
require 'errplane/rails/benchmarking'
require 'errplane/rails/instrumentation'

module InfluxDB
  module Rails
    def self.initialize
      ActionController::Base.send(:include, InfluxDB::Rails::AirTrafficController)
      ActionController::Base.send(:include, InfluxDB::Rails::Middleware::HijackRescueActionEverywhere)
      ActionController::Base.send(:include, InfluxDB::Rails::Benchmarking)
      ActionController::Base.send(:include, InfluxDB::Rails::Instrumentation)

      ::Rails.configuration.middleware.insert_after 'ActionController::Failsafe', InfluxDB::Rack

      InfluxDB.configure(true) do |config|
        config.logger                ||= ::Rails.logger
        config.debug                   = true
        config.environment           ||= ::Rails.env
        config.application_root      ||= ::Rails.root
        config.application_name      ||= "Application"
        config.framework               = "Rails"
        config.framework_version       = ::Rails.version
      end

      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          InfluxDB::Worker.spawn_threads() if forked
        end
      else
        InfluxDB::Worker.spawn_threads()
      end
    end
  end
end

InfluxDB::Rails.initialize

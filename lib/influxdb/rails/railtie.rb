require "influxdb"
require "rails"

module InfluxDB
  module Rails
    class Railtie < ::Rails::Railtie # :nodoc:
      initializer "influxdb.insert_rack_middleware" do |app|
        app.config.middleware.insert 0, InfluxDB::Rails::Rack
      end

      config.after_initialize do
        InfluxDB::Rails.configure(true, &:load_rails_defaults)

        ActiveSupport.on_load(:action_controller) do
          require "influxdb/rails/air_traffic_controller"
          include InfluxDB::Rails::AirTrafficController
          require "influxdb/rails/instrumentation"
          include InfluxDB::Rails::Instrumentation
        end

        require "influxdb/rails/middleware/hijack_render_exception"
        ::ActionDispatch::DebugExceptions.prepend InfluxDB::Rails::Middleware::HijackRenderException

        if defined?(ActiveSupport::Notifications)
          config = InfluxDB::Rails.configuration
          request_subsriber = Middleware::RequestSubscriber.new(config)
          ActiveSupport::Notifications.subscribe "process_action.action_controller", request_subsriber
        end
      end
    end
  end
end

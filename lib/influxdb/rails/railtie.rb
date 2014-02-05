require 'influxdb'
require 'rails'

module InfluxDB
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "influxdb.insert_rack_middleware" do |app|
        app.config.middleware.insert 0, InfluxDB::Rails::Rack
      end

      config.after_initialize do
        InfluxDB::Rails.configure(true) do |config|
          config.logger                ||= ::Rails.logger
          config.environment           ||= ::Rails.env
          config.application_root      ||= ::Rails.root
          config.application_name      ||= ::Rails.application.class.parent_name
          config.framework              = "Rails"
          config.framework_version       = ::Rails.version
        end

        ActiveSupport.on_load(:action_controller) do
          require 'influxdb/rails/air_traffic_controller'
          include InfluxDB::Rails::AirTrafficController
          require 'influxdb/rails/instrumentation'
          include InfluxDB::Rails::Instrumentation
        end

        if defined?(::ActionDispatch::DebugExceptions)
          require 'influxdb/rails/middleware/hijack_render_exception'
          ::ActionDispatch::DebugExceptions.send(:include, InfluxDB::Rails::Middleware::HijackRenderException)
        elsif defined?(::ActionDispatch::ShowExceptions)
          require 'influxdb/rails/middleware/hijack_render_exception'
          ::ActionDispatch::ShowExceptions.send(:include, InfluxDB::Rails::Middleware::HijackRenderException)
        end

        if defined?(ActiveSupport::Notifications)
          ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, start, finish, id, payload|
            if InfluxDB::Rails.configuration.instrumentation_enabled  && ! InfluxDB::Rails.configuration.ignore_current_environment?
              timestamp = finish.utc.to_i
              controller_runtime = ((finish - start)*1000).ceil
              view_runtime = (payload[:view_runtime] || 0).ceil
              db_runtime = (payload[:db_runtime] || 0).ceil
              controller_name = payload[:controller]
              action_name = payload[:action]
              hostname = Socket.gethostname

              InfluxDB::Rails.client.write_point "rails.controllers",
                :value => controller_runtime,
                :method => "#{controller_name}##{action_name}",
                :server => hostname

              InfluxDB::Rails.client.write_point "rails.views",
                :value => view_runtime,
                :method => "#{controller_name}##{action_name}",
                :server => hostname

              InfluxDB::Rails.client.write_point "rails.db",
                :value => db_runtime,
                :method => "#{controller_name}##{action_name}",
                :server => hostname
            end
          end
        end
      end
    end
  end
end

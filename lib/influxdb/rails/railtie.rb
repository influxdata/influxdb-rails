require 'influxdb'
require 'rails'

module InfluxDB
  module Rails
    class Railtie < ::Rails::Railtie # :nodoc:
      initializer "influxdb.insert_rack_middleware" do |app|
        app.config.middleware.insert 0, InfluxDB::Rails::Rack
      end

      # rubocop:disable Metrics/BlockLength

      config.after_initialize do
        InfluxDB::Rails.configure(true) do |config|
          config.logger           ||= ::Rails.logger
          config.environment      ||= ::Rails.env
          config.application_root ||= ::Rails.root
          config.application_name ||= ::Rails.application.class.parent_name
          config.framework          = "Rails"
          config.framework_version  = ::Rails.version
        end

        ActiveSupport.on_load(:action_controller) do
          require 'influxdb/rails/air_traffic_controller'
          include InfluxDB::Rails::AirTrafficController
          require 'influxdb/rails/instrumentation'
          include InfluxDB::Rails::Instrumentation
        end

        if defined?(::ActionDispatch::DebugExceptions)
          require 'influxdb/rails/middleware/hijack_render_exception'
          exceptions_class = ::ActionDispatch::DebugExceptions
        elsif defined?(::ActionDispatch::ShowExceptions)
          require 'influxdb/rails/middleware/hijack_render_exception'
          exceptions_class = ::ActionDispatch::ShowExceptions
        end

        InfluxDB::Rails.safely_prepend(
          "HijackRenderException",
          from: InfluxDB::Rails::Middleware,
          to: exceptions_class
        )

        if defined?(ActiveSupport::Notifications)
          listen = lambda do |name, start, finish, id, payload|
            c = InfluxDB::Rails.configuration

            if c.instrumentation_enabled? && !c.ignore_current_environment?
              begin
                InfluxDB::Rails.handle_action_controller_metrics(name, start, finish, id, payload)
              rescue StandardError => e
                c.logger.error "[InfluxDB::Rails] Failed writing points to InfluxDB: #{e.message}"
              end
            end
          end

          ActiveSupport::Notifications.subscribe "process_action.action_controller", &listen
        end
      end

      # rubocop:enable Metrics/BlockLength
    end
  end
end

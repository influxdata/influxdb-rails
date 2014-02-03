require 'influxdb'
require 'rails'

module InfluxDB
  class Railtie < ::Rails::Railtie
    rake_tasks do
      namespace :influxdb do
        task :test => :environment do
          if InfluxDB.configuration.api_key.nil?
            puts "Hey, you need to define an API key first. Run `rails g influxdb <api-key>` if you didn't already."
            exit
          end

          InfluxDB.configure do |config|
            config.debug = true
            config.ignored_environments = []
          end

          data = [{:n => "tests", :p => [{:v => 1}]}]
          if InfluxDB.api.post(data)
            puts "Test data sent successfully!"
          else
            puts "Test failed! Check your network connection and try again."
          end
        end

        task :diagnose => :environment do
          if InfluxDB.configuration.api_key.nil?
            puts "Hey, you need to define an API key first. Run `rails g influxdb <api-key>` if you didn't already."
            exit
          end

          InfluxDB.configure do |config|
            config.ignored_environments = []
          end

          class ::InfluxDBSampleException < Exception; end;

          require ::Rails.root.join("app/controllers/application_controller.rb")

          puts "Setting up ApplicationController.."
          class ::ApplicationController
            prepend_before_filter :raise_sample_exception

            def raise_sample_exception
              raise ::InfluxDBSampleException.new("If you see this, InfluxDB is working.")
            end

            def influxdb_dummy_action; end
          end

          ::Rails.application.routes_reloader.execute_if_updated
          ::Rails.application.routes.draw do
            match "influxdb_test" => 'application#influxdb_dummy_action'
          end

          puts "Generating sample request.."
          env = ::Rack::MockRequest.env_for("/influxdb_test")

          puts "Attempting to raise exception via HTTP.."
          response = ::Rails.application.call(env)

          10.times do
            sleep 1
            break unless InfluxDB.api.last_response.nil?
          end

          if response.try(:first) == 500
            if InfluxDB.api.last_response.nil?
              puts "Uh oh. Your app threw an exception, but we didn't get a response. Check your network connection and try again."
            elsif InfluxDB.api.last_response.code == "201"
              puts "Done. Check your email or http://influxdb.com for the exception notice."
            else
              puts "That didn't work. The InfluxDB API said: #{InfluxDB.api.last_response.body}"
            end
          else
            puts "Request failed: #{response}"

            env["HTTPS"] = "on"
            puts "Attempting to raise exception via HTTPS.."
            response = ::Rails.application.call(env)

            if response.try(:first) == 500
              if InfluxDB.api.last_response.nil?
                puts "Uh oh. Your app threw an exception, but we didn't get a response. Check your network connection and try again."
              elsif InfluxDB.api.last_response.code == "201"
                puts "Done. Check your email or http://influxdb.com for the exception notice."
              else
                puts "That didn't work. The InfluxDB API said: #{InfluxDB.api.last_response.body}"
              end
            else
              puts "Request failed: #{response}"
              puts "We didn't get the exception we were expecting. Contact support@influxdb.com and send them all of this output."
            end
          end
        end
      end
    end

    initializer "influxdb.insert_rack_middleware" do |app|
      app.config.middleware.insert 0, InfluxDB::Rack
    end

    config.after_initialize do
      InfluxDB.configure(true) do |config|
        config.logger                ||= ::Rails.logger
        config.environment           ||= ::Rails.env
        config.application_root      ||= ::Rails.root
        config.application_name      ||= ::Rails.application.class.parent_name
        config.framework               = "Rails"
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
          if InfluxDB.configuration.instrumentation_enabled  && ! InfluxDB.configuration.ignore_current_environment?
            timestamp = finish.utc.to_i
            controller_runtime = ((finish - start)*1000).ceil
            view_runtime = (payload[:view_runtime] || 0).ceil
            db_runtime = (payload[:db_runtime] || 0).ceil
            controller_name = payload[:controller]
            action_name = payload[:action]

            dimensions = {:method => "#{controller_name}##{action_name}", :server => Socket.gethostname}
            InfluxDB.aggregate "controllers", :value => controller_runtime, :dimensions => dimensions
            InfluxDB.aggregate "views", :value => view_runtime, :dimensions => dimensions
            InfluxDB.aggregate "db", :value => db_runtime, :dimensions => dimensions
          end
        end
      end
    end
  end
end

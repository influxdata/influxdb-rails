require "active_support/concern"

module InfluxDB
  module Rails
    module Configurable
      extend ActiveSupport::Concern

      class_methods do
        def defaults
          @defaults ||= {}
        end

        def set_defaults(**values) # rubocop:disable Naming/AccessorMethodName:
          defaults.merge! values
          attr_accessor(*defaults.keys)
        end
      end

      def load_defaults
        self.class.defaults.each do |key, value|
          val = value.dup rescue value
          public_send "#{key}=", val
        end
      end
    end
    private_constant :Configurable

    class ClientConfig
      include Configurable

      set_defaults(
        hosts:          ["localhost"].freeze,
        port:           8086,
        username:       "root".freeze,
        password:       "root".freeze,
        database:       nil,
        async:          true,
        use_ssl:        false,
        retry:          nil,
        open_timeout:   5,
        read_timeout:   300,
        max_delay:      30,
        time_precision: "s".freeze
      )

      def initialize
        load_defaults
      end
    end
    private_constant :ClientConfig

    class Configuration
      include Configurable

      set_defaults(
        measurement_name:             "rails".freeze,

        report_controller_runtimes:   true,
        report_view_runtimes:         true,
        report_db_runtimes:           true,
        report_sql:                   false,
        report_render_template:       true,
        report_render_partial:        true,
        report_render_collection:     true,
        report_exceptions:            true,
        report_instrumentation:       true,

        tags_middleware:              ->(tags) { tags },
        rails_app_name:               nil,

        ignored_exceptions:           %w[
          ActiveRecord::RecordNotFound
          ActionController::RoutingError
        ].freeze,

        ignored_exception_messages:   [].freeze,
        ignored_reports:              [].freeze,
        ignored_environments:         %w[test cucumber selenium].freeze,
        ignored_user_agents:          %w[GoogleBot].freeze,
        environment_variable_filters: [
          /password/i,
          /key/i,
          /secret/i,
          /ps1/i,
          /rvm_.*_clr/i,
          /color/i,
        ].freeze,
        environment:                  ::Rails.env,

        backtrace_filters:            [
          ->(line) { line.gsub(%r{^\./}, "") },
          lambda { |line|
            return line if InfluxDB::Rails.configuration.application_root.to_s.empty?

            line.gsub(/#{InfluxDB::Rails.configuration.application_root}/, "[APP_ROOT]")
          },
          lambda { |line|
            if defined?(Gem) && !Gem.path.nil? && !Gem.path.empty?
              Gem.path.each { |path| line = line.gsub(/#{path}/, "[GEM_ROOT]") }
            end
            line
          },
        ].freeze,

        debug:                        false,
        instrumentation_enabled:      true
      )

      # config option set after_initialize
      attr_accessor \
        :environment,      # Rails.env
        :application_root, # Rails.root
        :application_name, # Rails.application.class.parent_name
        :framework,        # "Rails"
        :framework_version # Rails.version

      # configuration passed to InfluxDB::Client
      attr_reader :client

      # a logger instance
      attr_accessor :logger

      def initialize
        @client = ClientConfig.new
        load_defaults
      end

      def debug?
        @debug
      end

      def instrumentation_enabled?
        @instrumentation_enabled
      end

      def ignore_user_agent?(incoming_user_agent)
        return false if ignored_user_agents.nil?

        ignored_user_agents.any? { |agent| incoming_user_agent =~ /#{agent}/ }
      end

      def ignore_current_environment?
        ignored_environments.include?(environment)
      end

      def ignore_exception?(ex)
        !ignored_exception_messages.find { |msg| /.*#{msg}.*/ =~ ex.message }.nil? ||
          ignored_exceptions.include?(ex.class.to_s)
      end

      def define_custom_exception_data(&block)
        @custom_exception_data_handler = block
      end

      def add_custom_exception_data(exception_presenter)
        @custom_exception_data_handler&.call(exception_presenter)
      end

      private

      def initialize_http_connection
        Net::HTTP.new(@app_host, "80")
      end
    end
  end
end

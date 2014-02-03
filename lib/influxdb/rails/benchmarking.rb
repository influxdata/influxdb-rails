require 'benchmark'
require "socket"

module InfluxDB
  module Rails
    module Benchmarking
      def self.included(base)
        base.send(:alias_method_chain, :perform_action, :instrumentation)
        base.send(:alias_method_chain, :view_runtime, :instrumentation)
        base.send(:alias_method_chain, :active_record_runtime, :instrumentation)
      end

      private
      def perform_action_with_instrumentation
        ms = Benchmark.ms { perform_action_without_instrumentation }
        if InfluxDB.configuration.instrumentation_enabled && ! InfluxDB.configuration.ignore_current_environment?
          InfluxDB.aggregate "controllers", :value => ms.ceil, :dimensions => dimensions
        end
      end

      def view_runtime_with_instrumentation
        runtime = view_runtime_without_instrumentation
        if InfluxDB.configuration.instrumentation_enabled && ! InfluxDB.configuration.ignore_current_environment?
          InfluxDB.aggregate "views", :value => runtime.split.last.to_f.ceil, :dimensions => dimensions
        end
        runtime
      end

      def active_record_runtime_with_instrumentation
        runtime = active_record_runtime_without_instrumentation
        if InfluxDB.configuration.instrumentation_enabled && ! InfluxDB.configuration.ignore_current_environment?
          InfluxDB.aggregate "db", :value => runtime.split.last.to_f.ceil, :dimensions => dimensions
        end
        runtime
      end

      def dimensions
        { :method => "#{params[:controller]}##{params[:action]}", :server => Socket.gethostname }
      end
    end
  end
end

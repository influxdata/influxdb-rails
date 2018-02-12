module InfluxDB
  module Rails
    module Instrumentation # rubocop:disable Style/Documentation
      def benchmark_for_instrumentationn # rubocop:disable Metrics/MethodLength
        start = Time.now
        yield

        return if InfluxDB::Rails.configuration.ignore_current_environment?

        InfluxDB::Rails.client.write_point \
          "instrumentation",
          values: {
            value: ((Time.now - start) * 1000).ceil,
          },
          tags: {
            method: "#{controller_name}##{action_name}",
            server: Socket.gethostname,
          }
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods # rubocop:disable Style/Documentation
        def instrument(methods = [])
          methods = [methods] unless methods.is_a?(Array)
          around_filter :benchmark_for_instrumentation, only: methods
        end
      end
    end
  end
end

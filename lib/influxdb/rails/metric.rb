require "influxdb/rails/tags"

module InfluxDB
  module Rails
    class Metric
      def initialize(configuration:, timestamp:, tags: {}, values: {})
        @configuration = configuration
        @timestamp = timestamp
        @tags = tags
        @values = values
      end

      def write
        write_api.write(data: data)
      end

      private

      attr_reader :configuration, :tags, :values, :timestamp

      def data
        {
          fields: values.merge(InfluxDB::Rails.current.values),
          tags:   Tags.new(tags: tags, config: configuration).to_h,
          name:   configuration.measurement_name,
          time:   timestamp.utc,
        }
      end

      def write_api
        InfluxDB::Rails.write_api
      end
    end
  end
end

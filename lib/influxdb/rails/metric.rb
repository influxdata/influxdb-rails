require "influxdb/rails/tags"

module InfluxDB
  module Rails
    class Metric
      def initialize(configuration:, timestamp:, tags: {}, fields: {})
        @configuration = configuration
        @timestamp = timestamp
        @tags = tags
        @fields = fields
      end

      def write
        write_api.write(data: data)
      end

      private

      attr_reader :configuration, :tags, :fields, :timestamp

      def data
        {
          fields: fields.merge(InfluxDB::Rails.current.fields),
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

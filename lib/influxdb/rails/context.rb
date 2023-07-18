module InfluxDB
  module Rails
    class Context
      def reset
        Thread.current[:_influxdb_rails_tags] = {}
        Thread.current[:_influxdb_rails_fields] = {}
      end

      def tags
        Thread.current[:_influxdb_rails_tags].to_h
      end

      def tags=(tags)
        Thread.current[:_influxdb_rails_tags] = self.tags.merge(tags)
      end

      def fields
        Thread.current[:_influxdb_rails_fields].to_h
      end

      def fields=(fields)
        Thread.current[:_influxdb_rails_fields] = self.fields.merge(fields)
      end
    end
  end
end

module InfluxDB
  module Rails
    class Values
      def initialize(values: {})
        @values = values
      end

      def to_h
        expanded_values.reject do |_, value|
          value.nil? || value == ""
        end
      end

      private

      attr_reader :values

      def expanded_values
        values.merge(additional_values)
      end

      def additional_values
        InfluxDB::Rails.current.values
      end
    end
  end
end

module InfluxDB
  module Rails
    class TestClient
      cattr_accessor :metrics do
        []
      end

      def write(options = {})
        metrics << options[:data]
      end

      def create_write_api(*)
        self
      end
    end
  end
end

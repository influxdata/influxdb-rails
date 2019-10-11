require File.expand_path(File.dirname(__FILE__) + "/test_client")

module InfluxDB
  module Rails
    module Matchers
      def expect_metric(name: "rails", **options)
        expect(TestClient.metrics).to include(
          a_hash_including(options.merge(name: name))
        )
      end

      def expect_no_metric(name: "rails", **options)
        expect(TestClient.metrics).not_to include(
          a_hash_including(options.merge(name: name))
        )
      end
    end
  end
end

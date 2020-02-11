require File.expand_path(File.dirname(__FILE__) + "/test_client")
require "launchy"

module InfluxDB
  module Rails
    module Matchers
      def expect_metric(name: "rails", **options)
        expect(metrics).to include(
          a_hash_including(options.merge(name: name))
        )
      end

      def expect_no_metric(name: "rails", **options)
        expect(metrics).not_to include(
          a_hash_including(options.merge(name: name))
        )
      end

      def save_and_open_metrics
        dir = File.join(File.dirname(__FILE__), "..", "..", "tmp")
        FileUtils.mkdir_p(dir)
        file_path = File.join(dir, "metrics.json")
        output = JSON.pretty_generate(metrics)
        File.write(file_path, output, mode: "wb")
        ::Launchy.open(file_path)
      end

      private

      def metrics
        TestClient.metrics
      end
    end
  end
end

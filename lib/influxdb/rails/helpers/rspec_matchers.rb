require_relative "../test_client"
require "launchy"

module InfluxDB
  module Rails
    module Matchers
      def expect_metric(name: "rails", tags: a_hash_including, fields: a_hash_including, **options)
        expect(filtered_metrics(tags)).to include(
          a_hash_including(
            name:   name,
            tags:   tags,
            fields: fields,
            **options
          )
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

      def capture_influxdb_output
        orig_logger = InfluxDB::Rails.logger
        out = StringIO.new
        InfluxDB::Rails.logger = Logger.new(out)

        yield

        out.string
      ensure
        InfluxDB::Rails.logger = orig_logger
      end

      RSpec.configure do |config|
        config.before :each do
          InfluxDB::Rails.instance_variable_set :@configuration, nil
          InfluxDB::Rails.configure do |cfg|
            cfg.logger = Logger.new($stdout)
          end

          InfluxDB::Rails.client = InfluxDB::Rails::TestClient.new
          allow_any_instance_of(InfluxDB::Rails::Configuration)
            .to receive(:ignored_environments).and_return(%w[development])

          InfluxDB::Rails::TestClient.metrics.clear
        end

        config.include InfluxDB::Rails::Matchers
      end

      private

      def filtered_metrics(tags)
        if tags.expecteds.first[:hook]
          metrics.select do |metric|
            metric.dig(:tags, :hook) == tags.expecteds.first[:hook]
          end
        else
          metrics
        end
      end

      def metrics
        TestClient.metrics
      end
    end
  end
end

require "spec_helper"
require "shared_examples/data"

RSpec.describe InfluxDB::Rails::Middleware::RequestSubscriber do
  let(:config) { InfluxDB::Rails::Configuration.new }

  before do
    allow(config.client).to receive(:time_precision).and_return("ms")
    allow(config).to receive(:environment).and_return("production")
  end

  subject { described_class.new(config, "process_action.action_controller") }

  describe "#call" do
    let(:start)   { Time.at(1_517_567_368) }
    let(:finish)  { Time.at(1_517_567_370) }
    let(:payload) { { view_runtime: 2, db_runtime: 2, controller: "MyController", action: "show", method: "GET", format: "*/*", status: 200 } }
    let(:data)    do
      {
        values:    {
          controller: 2,
          started:    InfluxDB.convert_timestamp(start.utc, config.client.time_precision),
        },
        tags:      {
          method:      "MyController#show",
          hook:        "process_action",
          status:      200,
          format:      "*/*",
          http_method: "GET",
          server:      Socket.gethostname,
          app_name:    "my-rails-app",
        },
        timestamp: 1_517_567_370_000
      }
    end

    context "application_name is set" do
      before do
        allow(config).to receive(:application_name).and_return("my-rails-app")
      end

      it "sends metrics with taggings and timestamps" do
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(
          config.measurement_name, data.deep_merge(values: { controller: 2000, db: 2, view: 2 })
        )

        subject.call("unused", start, finish, "unused", payload)
      end

      it_behaves_like "with additional data", ["requests"]
    end

    context "application_name is nil" do
      let(:tags) do
        {
          method:      "MyController#show",
          hook:        "process_action",
          status:      200,
          format:      "*/*",
          http_method: "GET",
          server:      Socket.gethostname,
        }
      end

      before do
        allow(config).to receive(:application_name).and_return(nil)
      end

      it "does not add the app_name tag to metrics" do
        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(
          config.measurement_name, data.merge(tags: tags).deep_merge(values: { controller: 2000, db: 2, view: 2 })
        )

        subject.call("unused", start, finish, "unused", payload)
      end
    end

    context "not successfull" do
      before do
        InfluxDB::Rails.configuration = config
      end

      it "does log an error" do
        allow_any_instance_of(InfluxDB::Client).to receive(:write_point).and_raise("boom")
        expect(::Rails.logger).to receive(:error).with(/boom/)
        subject.call("name", start, finish, "id", payload)
      end
    end

    context "disabled" do
      before do
        allow(config).to receive(:ignored_hooks).and_return(["process_action.action_controller"])
      end

      subject { described_class.new(config, "process_action.action_controller") }

      it "does not write a data point" do
        expect_any_instance_of(InfluxDB::Client).not_to receive(:write_point)
        subject.call("name", start, finish, "id", payload)
      end
    end
  end
end

require "spec_helper"

RSpec.shared_examples_for "with additional data" do
  context "values" do
    let(:additional_values) do
      { another: :value }
    end

    after do
      InfluxDB::Rails.current.reset
    end

    it "does include the tags" do
      InfluxDB::Rails.current.values = additional_values

      expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(config.measurement_name, hash_including(values: hash_including(another: :value)))

      subject.call("unused", start, finish, "unused", payload)
    end
  end

  context "tags" do
    context "when tags_middleware is overwritten" do
      before do
        allow(config).to receive(:tags_middleware).and_return(tags_middleware)
      end

      let(:tags_middleware) { ->(tags) { tags.merge(static: "value", nil: nil, empty: "") } }

      it "processes tags throught the middleware" do
        tags = data[:tags].merge(static: "value")

        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(config.measurement_name, include(tags: tags))

        subject.call("unused", start, finish, "unused", payload)
      end
    end

    context "when tags are set in the current context" do
      let(:input) do
        { another: :value, nil: nil, empty: "" }
      end
      let(:output) do
        { another: :value }
      end

      after do
        InfluxDB::Rails.current.reset
      end

      it "does include the tags" do
        InfluxDB::Rails.current.tags = input
        tags = data[:tags].merge(output)

        expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(config.measurement_name, include(tags: tags))

        subject.call("unused", start, finish, "unused", payload)
      end
    end
  end
end

require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe "ActionView collection metrics", type: :request do
  let(:tags_middleware) do
    lambda do |tags|
      tags.merge(tags_middleware: :tags_middleware)
    end
  end
  before do
    allow_any_instance_of(ActionDispatch::Request).to receive(:request_id).and_return(:request_id)
    allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:application_name).and_return(:app_name)
    allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:tags_middleware).and_return(tags_middleware)
  end

  it "writes metric" do
    get "/metrics"

    expect_metric(
      name:   "rails",
      tags:   a_hash_including(
        location:        "MetricsController#index",
        hook:            "render_collection",
        additional_tag:  :value,
        filename:        include("spec/support/views/metrics/_item.html.erb"),
        server:          Socket.gethostname,
        app_name:        :app_name,
        tags_middleware: :tags_middleware
      ),
      values: a_hash_including(
        additional_value: :value,
        count:            3,
        request_id:       :request_id,
        value:            be_between(1, 30)
      )
    )
  end

  it "includes correct timestamps" do
    travel_to Time.zone.local(2018, 1, 1, 9, 0, 0)

    get "/metrics"

    expect_metric(
      name:      "rails",
      tags:      a_hash_including(
        location: "MetricsController#index",
        hook:     "render_collection"
      ),
      timestamp: 1_514_797_200
    )
  end

  it "does not write metric when hook is ignored" do
    allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:ignored_hooks).and_return(["render_collection.action_view"])

    get "/metrics"

    expect_no_metric(
      name: "rails",
      tags: a_hash_including(
        location: "MetricsController#index",
        hook:     "render_collection"
      )
    )
  end
end

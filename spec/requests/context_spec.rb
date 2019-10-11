require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe "Context", type: :request do
  before do
    allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:ignored_environments).and_return(%w[development])
  end

  it "resets the context between requests" do
    get "/metrics"

    expect_metric(
      tags: a_hash_including(
        method: "MetricsController#index",
        hook:   "process_action"
      )
    )

    get "/exceptions"

    expect_metric(
      name: "rails",
      tags: a_hash_including(
        method: "ExceptionsController#index",
        hook:   "process_action"
      )
    )
  end
end

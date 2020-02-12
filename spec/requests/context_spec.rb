require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe "Context", type: :request do
  before do
    allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:ignored_environments).and_return(%w[development])
  end

  it "resets the context after a request" do
    get "/metrics"

    expect_metric(
      tags: a_hash_including(
        location: "MetricsController#index",
        hook:     "sql"
      )
    )

    expect(InfluxDB::Rails.current.tags).to be_empty
    expect(InfluxDB::Rails.current.values).to be_empty
  end

  it "resets the context after a request when exceptioni occurs" do
    get "/exceptions"

    expect_metric(
      name: "rails",
      tags: a_hash_including(
        method: "ExceptionsController#index",
        hook:   "process_action"
      )
    )

    expect(InfluxDB::Rails.current.tags).to be_empty
    expect(InfluxDB::Rails.current.values).to be_empty
  end
end

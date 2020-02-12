require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe "Context", type: :request do
  before do
    allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:ignored_environments).and_return(%w[development])
  end

  it "logs exception" do
    setup_broken_client
    expect(Rails.logger).to receive(:error).with(/message/).at_least(:once)

    get "/metrics"
  end
end

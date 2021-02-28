require "#{File.dirname(__FILE__)}/../spec_helper"

RSpec.describe "Logger" do
  it "logs exception" do
    InfluxDB::Rails.client = build_broken_client("error message")

    out = capture_influxdb_output do
      get "/metrics"
    end

    assert_includes out, "error message"
  end
end

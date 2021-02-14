require "#{File.dirname(__FILE__)}/../spec_helper"

RSpec.describe "Logger" do
  it "logs exception" do
    InfluxDB::Rails.client = build_broken_client("error message")
    io = StringIO.new
    Rails.logger = Logger.new(io)

    get "/metrics"

    assert_includes io.string, "error message"
  end
end

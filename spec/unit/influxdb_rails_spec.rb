require "spec_helper"

RSpec.describe InfluxDB::Rails do
  before do
    InfluxDB::Rails.configure do |config|
      config.application_name = "my-rails-app"
      config.ignored_environments = []
      config.time_precision = "ms"
    end
  end

  describe ".current_timestamp" do
    it "should return the current timestamp in the configured precision" do
      now = Time.parse("2017-12-11 16:20:29.111222333 UTC")
      allow(Time).to receive(:now).and_return(now)
      InfluxDB::Rails.configure { |config| config.time_precision = "ms" }
      expect(InfluxDB::Rails.current_timestamp).to eq(1_513_009_229_111)
    end
  end

  describe ".ignorable_exception?" do
    it "should be true for exception types specified in the configuration" do
      class DummyException < RuntimeError; end
      exception = DummyException.new

      InfluxDB::Rails.configure do |config|
        config.ignored_exceptions << "DummyException"
      end

      expect(InfluxDB::Rails.ignorable_exception?(exception)).to be_truthy
    end

    it "should be true for exception types specified in the configuration" do
      exception = ActionController::RoutingError.new("foo")
      expect(InfluxDB::Rails.ignorable_exception?(exception)).to be_truthy
    end

    it "should be false for valid exceptions" do
      exception = ZeroDivisionError.new
      expect(InfluxDB::Rails.ignorable_exception?(exception)).to be_falsey
    end
  end

  describe "rescue" do
    it "should transmit an exception when passed" do
      expect(InfluxDB::Rails.client).to receive(:write_point)

      InfluxDB::Rails.rescue do
        raise ArgumentError, "wrong"
      end
    end

    it "should also raise the exception when in an ignored environment" do
      InfluxDB::Rails.configure do |config|
        config.ignored_environments = %w[development test]
      end

      expect do
        InfluxDB::Rails.rescue do
          raise ArgumentError, "wrong"
        end
      end.to raise_error(ArgumentError)
    end
  end

  describe "rescue_and_reraise" do
    it "should transmit an exception when passed" do
      expect(InfluxDB::Rails.client).to receive(:write_point)

      expect do
        InfluxDB::Rails.rescue_and_reraise { raise ArgumentError, "wrong" }
      end.to raise_error(ArgumentError)
    end
  end
end

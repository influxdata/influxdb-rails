require 'spec_helper'

describe InfluxDB::Rails do
  before do
    InfluxDB::Rails.configure { |config| config.ignored_environments = [] }
  end

  describe ".ignorable_exception?" do
    it "should be true for exception types specified in the configuration" do
      class DummyException < Exception; end
      exception = DummyException.new

      InfluxDB::Rails.configure do |config|
        config.ignored_exceptions << 'DummyException'
      end

      InfluxDB::Rails.ignorable_exception?(exception).should be_true
    end

    it "should be true for exception types specified in the configuration" do
      exception = ActionController::RoutingError.new("foo")
      InfluxDB::Rails.ignorable_exception?(exception).should be_true
    end

    it "should be false for valid exceptions" do
      exception = ZeroDivisionError.new
      InfluxDB::Rails.ignorable_exception?(exception).should be_false
    end
  end

  describe 'rescue' do
    it "should transmit an exception when passed" do
      InfluxDB::Rails.configure do |config|
        config.ignored_environments = []
        config.instrumentation_enabled = false
      end

      InfluxDB::Rails.client.should_receive(:write_point)

      InfluxDB::Rails.rescue do
        raise ArgumentError.new('wrong')
      end
    end

    it "should also raise the exception when in an ignored environment" do
      InfluxDB::Rails.configure { |config| config.ignored_environments = %w{development test} }

      expect {
        InfluxDB::Rails.rescue do
          raise ArgumentError.new('wrong')
        end
      }.to raise_error(ArgumentError)
    end
  end

  describe "rescue_and_reraise" do
    it "should transmit an exception when passed" do
      InfluxDB::Rails.configure { |config| config.ignored_environments = [] }

      InfluxDB::Rails.client.should_receive(:write_point)

      expect {
        InfluxDB::Rails.rescue_and_reraise { raise ArgumentError.new('wrong') }
      }.to raise_error(ArgumentError)
    end
  end
end

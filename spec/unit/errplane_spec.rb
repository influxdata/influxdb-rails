require 'spec_helper'

describe InfluxDB do
  before do
    InfluxDB.configure { |config| config.ignored_environments = [] }

    FakeWeb.last_request = nil
    FakeWeb.clean_registry

    @request_path = "/api/v1/applications/#{InfluxDB.configuration.application_id}/exceptions/test?api_key=f123-e456-d789c012"
    @request_url = "http://api.errplane.com#{@request_path}"
  end

  describe ".ignorable_exception?" do
    it "should be true for exception types specified in the configuration" do
      class DummyException < Exception; end
      exception = DummyException.new

      InfluxDB.configure do |config|
        config.ignored_exceptions << 'DummyException'
      end

      InfluxDB.ignorable_exception?(exception).should be_true
    end

    it "should be true for exception types specified in the configuration" do
      exception = ActionController::RoutingError.new("foo")
      InfluxDB.ignorable_exception?(exception).should be_true
    end

    it "should be false for valid exceptions" do
      exception = ZeroDivisionError.new
      InfluxDB.ignorable_exception?(exception).should be_false
    end
  end

  describe 'rescue' do
    it "should transmit an exception when passed" do
      InfluxDB.queue.clear

      InfluxDB.configure do |config|
        config.ignored_environments = []
        config.instrumentation_enabled = false
      end

      InfluxDB.rescue do
        raise ArgumentError.new('wrong')
      end

      InfluxDB.queue.size.should == 1
    end

    it "should also raise the exception when in an ignored environment" do
      InfluxDB.configure { |config| config.ignored_environments = %w{development test} }

      expect {
        InfluxDB.rescue do
          raise ArgumentError.new('wrong')
        end
      }.to raise_error(ArgumentError)
    end
  end

  describe "rescue_and_reraise" do
    it "should transmit an exception when passed" do
      InfluxDB.configure { |config| config.ignored_environments = [] }
      InfluxDB.queue.clear

      expect {
        InfluxDB.rescue_and_reraise { raise ArgumentError.new('wrong') }
      }.to raise_error(ArgumentError)

      InfluxDB.queue.size.should == 1
    end
  end
end

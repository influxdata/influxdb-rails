require File.expand_path(File.dirname(__FILE__) + "/integration_helper")

describe "exception handling" do
  before do
    InfluxDB::Rails.configure do |config|
      config.ignored_environments = %w{development}
      config.instrumentation_enabled = false
    end
  end

  describe "in an action that raises an exception" do
    it "should add an exception to the queue" do
      # InfluxDB.queue.size.should == 0
      get "/widgets/new"
      # InfluxDB.queue.size.should == 1
    end
  end

  describe "in an action that does not raise an exception" do
    it "should not add anything to the queue" do
      get "/widgets"
      # InfluxDB.queue.size.should == 0
    end
  end

  describe "for an ignored user agent" do
    it "should not make an HTTP call to the API" do
      InfluxDB::Rails.configure do |config|
        config.ignored_user_agents = %w{Googlebot}
      end
      get "/widgets/new", {}, { "HTTP_USER_AGENT" => "Googlebot/2.1" }
      # InfluxDB.queue.size.should == 0
    end
  end
end


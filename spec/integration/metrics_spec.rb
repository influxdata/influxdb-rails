require File.expand_path(File.dirname(__FILE__) + "/integration_helper")

RSpec.describe WidgetsController, type: :controller do
  render_views

  before do
    allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:ignored_environments).and_return(%w[development])
  end

  describe "in a normal request" do
    it "should result in attempts to write metrics via the client" do
      expect(InfluxDB::Rails.client).to receive(:write_point).exactly(6).times
      get :index
    end

    context "with sql reports enabled" do
      before do
        allow_any_instance_of(InfluxDB::Rails::Middleware::SqlSubscriber).to receive(:series_name).and_return("rails.sql")
        get :index # to not count ActiveRecord initialization
      end

      it "should result in attempts to write metrics via the client" do
        expect(InfluxDB::Rails.client).to receive(:write_point).exactly(7).times
        get :index
      end
    end
  end
end

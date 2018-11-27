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
  end
end

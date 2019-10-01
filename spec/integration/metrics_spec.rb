require File.expand_path(File.dirname(__FILE__) + "/integration_helper")

RSpec.describe "User visits widgets", type: :request do
  before do
    allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:ignored_environments).and_return(%w[development])
  end

  describe "in a normal request" do
    it "should result in attempts to write metrics via the client" do
      expect(InfluxDB::Rails.client).to receive(:write_point).exactly(5).times
      get "/widgets"
    end

    context "additional values" do
      it "should result in attempts to write metrics via the client" do
        allow_any_instance_of(ActionDispatch::Request).to receive(:request_id).and_return(:request_id)
        expect(InfluxDB::Rails.client).to receive(:write_point).with(
          "rails", a_hash_including(
                     tags:   a_hash_including(method: "WidgetsController#index", hook: "process_action"),
                     values: a_hash_including(request_id: :request_id, key: :value)
                   )
        )
        get "/widgets"
      end
    end
  end
end

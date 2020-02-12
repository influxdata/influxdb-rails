$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "active_support"
require File.expand_path(File.dirname(__FILE__) + "/support/matchers")
require File.expand_path(File.dirname(__FILE__) + "/support/broken_client")

ENV["RAILS_ENV"] ||= "test"

require "rails"

if Rails::VERSION::MAJOR < 4 || Rails::VERSION::MAJOR == 4 && Rails::VERSION::MINOR < 2
  raise "Sorry, influxdb-rails only supports Rails 4.2 and higher."
end

require "bundler/setup"
Bundler.require

require "fakeweb"
FakeWeb.allow_net_connect = false

puts "Loading Rails v#{Rails.version}..."

require "support/rails#{Rails::VERSION::MAJOR}/app"
require "rspec/rails"

require "pry"

RSpec.configure do |config|
  # use expect syntax
  config.disable_monkey_patching!

  # reset configuration for each spec
  config.before :each do
    InfluxDB::Rails.instance_variable_set :@configuration, nil
    InfluxDB::Rails.configure

    allow(InfluxDB::Rails).to receive(:client).and_return(InfluxDB::Rails::TestClient.new)
    InfluxDB::Rails::TestClient.metrics.clear
  end

  config.after(:each) do
    travel_back
  end

  config.include ActiveSupport::Testing::TimeHelpers
  config.include InfluxDB::Rails::Matchers
  config.include InfluxDB::Rails::BrokenClient
end

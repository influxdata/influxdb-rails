$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "active_support"
require_relative "../lib/influxdb/rails/helpers/rspec_matchers"
require File.expand_path("#{File.dirname(__FILE__)}/support/broken_client")

ENV["RAILS_ENV"] ||= "test"

require "rails"

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

  config.after do
    travel_back
  end

  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActiveSupport::Testing::Assertions
  config.include ActiveJob::TestHelper

  config.include InfluxDB::Rails::BrokenClient
end

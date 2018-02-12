$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
ENV["RAILS_ENV"] ||= "test"

require "rails"

if Rails::VERSION::MAJOR < 4
  raise "Sorry, influxdb-rails only supports Rails 4.x and higher."
end

require 'bundler/setup'
Bundler.require

require "fakeweb"
FakeWeb.allow_net_connect = false

puts "Loading Rails v#{Rails.version}..."

if Rails.version.to_f < 5.0
  require "support/rails4/app"
  require "rspec/rails"
else
  require "support/rails5/app"
  require "rspec/rails"
end

RSpec.configure do |config|
  # use expect syntax
  config.disable_monkey_patching!

  # reset configuration for each spec
  config.before :each do
    InfluxDB::Rails.instance_variable_set :@configuration, nil
    InfluxDB::Rails.configure do |c|
      c.environment = "test"
    end
  end
end

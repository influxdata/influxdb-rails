require 'rails/generators'

class InfluxdbGenerator < Rails::Generators::Base
  desc "Description:\n  This creates a Rails initializer for InfluxDB."

  puts "Creating things"
  source_root File.expand_path('../templates', __FILE__)

  def copy_initializer_file
    template "initializer.rb", "config/initializers/influxdb.rb"
  end

  def install
  end
end

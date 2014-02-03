require 'rails/generators'

class InfluxDBGenerator < Rails::Generators::Base
  desc "Description:\n  This creates a Rails initializer for InfluxDB."

  begin
    if ARGV.count == 1
      puts "No Application ID provided, contacting InfluxDB API."
      application_name = Rails.application.class.parent_name || "NewApplication"
      api_key = ARGV.first

      connection = Net::HTTP.new("influxdb.com", 443)
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      url = "/api/v1/applications?api_key=#{api_key}&name=#{application_name}"
      response = connection.post(url, nil)

      unless response.is_a?(Net::HTTPSuccess)
        raise "The InfluxDB API returned an error: #{response.inspect}"
      end

      @application = JSON.parse(response.body)
      @application_id = @application["key"]
    else
      @application_id = ARGV[1]
    end
    puts "Received Application ID: #{@application_id}"

  rescue => e
    puts "We ran into a problem creating your application via the API!"
    puts "If this issue persists, contact us at support@influxdb.com with the following details:"
    puts "#{e.class}: #{e.message}"
  end

  source_root File.expand_path('../templates', __FILE__)
  argument :api_key,
    :required => true,
    :type => :string,
    :description => "API key for your InfluxDB organization"
  argument :application_id,
    :required => false,
    :default => @application_id,
    :type => :string,
    :description => "Identifier for this application (Leave blank and a new one will be generated for you)"

  def copy_initializer_file
    template "initializer.rb", "config/initializers/influxdb.rb"
  end

  def install
  end
end

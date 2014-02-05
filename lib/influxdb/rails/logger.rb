module InfluxDB
  module Rails
    module Logger
      PREFIX = "[InfluxDB::Rails] "

      private
      def log(level, message)
        return if level != :error && ! InfluxDB::Rails.configuration.debug?
        InfluxDB::Rails.configuration.logger.send(level, PREFIX + message) if InfluxDB.configuration.logger
      end
    end
  end
end

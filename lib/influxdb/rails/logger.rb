module InfluxDB
  module Rails
    module Logger
      PREFIX = "[InfluxDB::Rails] "

      private
      def log(level, message)
        return if level != :error && !InfluxDB.configuration.debug?
        InfluxDB.configuration.logger.send(level, PREFIX + message) if InfluxDB.configuration.logger
      end
    end
  end
end

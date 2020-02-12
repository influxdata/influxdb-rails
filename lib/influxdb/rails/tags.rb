module InfluxDB
  module Rails
    class Tags
      def initialize(tags: {}, config:)
        @tags = tags
        @config = config
      end

      def to_h
        expanded_tags.reject do |_, value|
          value.nil? || value == ""
        end
      end

      private

      attr_reader :tags, :config

      def expanded_tags
        config.tags_middleware.call(tags.merge(default_tags))
      end

      def default_tags
        {
          server:   Socket.gethostname,
          app_name: config.application_name,
        }.merge(InfluxDB::Rails.current.tags)
      end

      def current
        @current ||= InfluxDB::Rails.current
      end
    end
  end
end

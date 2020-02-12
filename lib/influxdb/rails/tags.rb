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
        config.tags_middleware.call(default_tags.merge(tags))
      end

      def default_tags
        {
          server:   Socket.gethostname,
          app_name: config.application_name,
          location: location.presence || default_location,
        }.merge(InfluxDB::Rails.current.tags)
      end

      def location
        [
          current.controller,
          current.action,
        ].reject(&:blank?).join("#")
      end

      def default_location
        :raw
      end

      def current
        @current ||= InfluxDB::Rails.current
      end
    end
  end
end

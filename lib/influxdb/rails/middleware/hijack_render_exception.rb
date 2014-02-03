module InfluxDB
  module Rails
    module Middleware
      module HijackRenderException
        def self.included(base)
          base.send(:alias_method_chain, :render_exception, :errplane)
        end

        def render_exception_with_errplane(env, e)
          controller = env["action_controller.instance"]
          request_data = controller.try(:errplane_request_data) || {}
          unless InfluxDB.configuration.ignore_user_agent?(request_data[:user_agent])
            InfluxDB.report_exception_unless_ignorable(e, request_data)
          end
          render_exception_without_errplane(env, e)
        end
      end
    end
  end
end


# frozen_string_literal: true

# app/controllers/integrations/searchlight/v1/dashboards_controller.rb
module Integrations
  module Searchlight
    module V1
      class DashboardsController < Searchlight::V1::IntegrationsController
        # (GET) show SearchLight dashboard screen
        # /integrations/searchlight/v1/dashboard
        # integrations_searchlight_v1_dashboard_path
        # integrations_searchlight_v1_dashboard_url
        def show
          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { render 'integrations/searchlight/v1/dashboard/show' }
          end
        end
      end
    end
  end
end

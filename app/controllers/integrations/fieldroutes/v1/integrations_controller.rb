# frozen_string_literal: true

# app/controllers/integrations/fieldroutes/v1/integrations_controller.rb
module Integrations
  module Fieldroutes
    module V1
      class IntegrationsController < Fieldroutes::IntegrationsController
        # (GET) show main FieldRoutes integration screen
        # /integrations/fieldroutes/v1
        # integrations_fieldroutes_v1_path
        # integrations_fieldroutes_v1_url
        def show
          respond_to do |format|
            format.turbo_stream
            format.html { render 'integrations/fieldroutes/v1/show' }
          end
        end
      end
    end
  end
end

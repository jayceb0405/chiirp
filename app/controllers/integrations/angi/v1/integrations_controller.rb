# frozen_string_literal: true

# app/controllers/integrations/angi/v1/integrations_controller.rb
module Integrations
  module Angi
    module V1
      class IntegrationsController < Angi::IntegrationsController
        # (GET) show main Angi integration screen
        # /integrations/angi/v1
        # integrations_angi_v1_path
        # integrations_angi_v1_url
        def show
          respond_to do |format|
            format.turbo_stream
            format.html { render 'integrations/angi/v1/show' }
          end
        end
      end
    end
  end
end

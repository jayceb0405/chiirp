# frozen_string_literal: true

# app/controllers/integrations/jotform/v2024311/integrations_controller.rb
module Integrations
  module Jotform
    module V1
      class IntegrationsController < Jotform::IntegrationsController
        # (GET) show main JotForm integration screen
        # /integrations/jotform/v1
        # integrations_jotform_v1_path
        # integrations_jotform_v1_url
        def show
          respond_to do |format|
            format.turbo_stream
            format.html { render 'integrations/jotform/v1/show' }
          end
        end
      end
    end
  end
end

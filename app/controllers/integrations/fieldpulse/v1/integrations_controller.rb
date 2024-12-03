# frozen_string_literal: true

# app/controllers/integrations/fieldpulse/v1/integrations_controller.rb
module Integrations
  module Fieldpulse
    module V1
      class IntegrationsController < Fieldpulse::IntegrationsController
        # (GET) show main FieldPulse integration screen
        # /integrations/fieldpulse/v1
        # integrations_fieldpulse_v1_path
        # integrations_fieldpulse_v1_url
        def show
          respond_to do |format|
            format.turbo_stream
            format.html { render 'integrations/fieldpulse/v1/show' }
          end
        end
      end
    end
  end
end

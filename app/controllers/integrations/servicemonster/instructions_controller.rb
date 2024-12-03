# frozen_string_literal: true

# app/controllers/integrations/servicemonster/instructions_controller.rb
module Integrations
  module Servicemonster
    # support for displaying user instructions for ServiceMonster integration
    class InstructionsController < Servicemonster::IntegrationsController
      # (GET) ServiceMonster integration instructions screen
      # /integrations/servicemonster/instructions
      # integrations_servicemonster_instructions_path
      # integrations_servicemonster_instructions_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[instructions_show] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end
    end
  end
end

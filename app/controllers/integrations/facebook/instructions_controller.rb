# frozen_string_literal: true

# app/controllers/integrations/facebook/instructions_controller.rb
module Integrations
  module Facebook
    class InstructionsController < Facebook::IntegrationsController
      # (GET) show instructions page for Facebook integration
      # /integrations/facebook/instructions
      # integrations_facebook_instructions_path
      # integrations_facebook_instructions_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/facebook/js/show', locals: { cards: %w[show_instructions] } }
          format.html { redirect_to integrations_facebook_integration_path }
        end
      end
    end
  end
end

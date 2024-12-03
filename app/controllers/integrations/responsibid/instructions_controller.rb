# frozen_string_literal: true

# app/controllers/integrations/responsibid/instructions_controller.rb
module Integrations
  module Responsibid
    # support for displaying user instructions for ResponsiBid integration
    class InstructionsController < Responsibid::IntegrationsController
      # (GET) ResponsiBid integration instructions screen
      # /integrations/responsibid/instructions
      # integrations_responsibid_instructions_path
      # integrations_responsibid_instructions_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/responsibid/js/show', locals: { cards: %w[instructions_show] } }
          format.html { redirect_to integrations_responsibid_path }
        end
      end
    end
  end
end

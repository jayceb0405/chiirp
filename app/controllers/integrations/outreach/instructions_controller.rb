# frozen_string_literal: true

# app/controllers/integrations/outreach/instructions_controller.rb
module Integrations
  module Outreach
    # support for displaying user instructions for Outreach integration
    class InstructionsController < Outreach::IntegrationsController
      # (GET) Outreach integration instructions screen
      # /integrations/outreach/instructions
      # integrations_outreach_instructions_path
      # integrations_outreach_instructions_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/outreach/js/show', locals: { cards: %w[instructions_show] } }
          format.html { render 'integrations/outreach/show' }
        end
      end
    end
  end
end

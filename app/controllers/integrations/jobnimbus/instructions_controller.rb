# frozen_string_literal: true

# app/controllers/integrations/jobnimbus/instructions_controller.rb
module Integrations
  module Jobnimbus
    # support for displaying user instructions for JobNimbus integration
    class InstructionsController < Jobnimbus::IntegrationsController
      # (GET) JobNimbus integration instructions screen
      # /integrations/jobnimbus/instructions
      # integrations_jobnimbus_instructions_path
      # integrations_jobnimbus_instructions_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/jobnimbus/js/show', locals: { cards: %w[instructions_show] } }
          format.html { redirect_to integrations_jobnimbus_path }
        end
      end
    end
  end
end

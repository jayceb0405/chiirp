# frozen_string_literal: true

# app/controllers/integrations/google/instructions_controller.rb
module Integrations
  module Google
    class InstructionsController < Google::IntegrationsController
      # (GET) Google integration instructions screen
      # /integrations/google/instructions
      # integrations_google_instructions_path
      # integrations_google_instructions_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/google/js/show', locals: { cards: %w[instructions_show] } }
          format.html { render 'integrations/google/edit' }
        end
      end
    end
  end
end

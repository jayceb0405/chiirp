# frozen_string_literal: true

# app/controllers/integrations/housecall/instructions_controller.rb
module Integrations
  module Housecall
    class InstructionsController < Housecall::IntegrationsController
      # (GET) Housecall Pro integration instructions screen
      # /integrations/housecall/instructions
      # integrations_housecall_instructions_path
      # integrations_housecall_instructions_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[instructions_show] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end
    end
  end
end

# frozen_string_literal: true

# app/controllers/integrations/webhook/instructions_controller.rb
module Integrations
  module Webhook
    class InstructionsController < Webhook::IntegrationsController
      # (GET) Webhook integration instructions screen
      # /integrations/webhook/instructions
      # integrations_webhook_instructions_path
      # integrations_webhook_instructions_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/webhooks/js/show', locals: { cards: %w[instructions_show] } }
          format.html { render 'integrations/webhooks/show' }
        end
      end
    end
  end
end

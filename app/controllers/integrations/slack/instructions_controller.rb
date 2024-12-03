# frozen_string_literal: true

# app/controllers/integrations/slack/instructions_controller.rb
module Integrations
  module Slack
    class InstructionsController < Slack::IntegrationsController
      # (GET) show instructions page for Slack integration
      # /integrations/slack/instructions
      # integrations_slack_instructions_path
      # integrations_slack_instructions_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/slack/js/show', locals: { cards: %w[show_instructions] } }
          format.html { redirect_to integrations_slack_integration_path }
        end
      end
    end
  end
end

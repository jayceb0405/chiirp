# frozen_string_literal: true

# app/controllers/integrations/sendgrid/v1/instructions_controller.rb
module Integrations
  module Sendgrid
    module V1
      class InstructionsController < Sendgrid::V1::IntegrationsController
        before_action :authenticate_user!
        before_action :authorize_user!

        # (GET) SendGrid integration instructions screen
        # /integrations/sendgrid/v1/instructions
        # integrations_housecall_instructions_path
        # integrations_housecall_instructions_url
        def show
          render partial: 'integrations/sendgrid/v1/js/show', locals: { cards: %w[instructions_show] }
        end
      end
    end
  end
end

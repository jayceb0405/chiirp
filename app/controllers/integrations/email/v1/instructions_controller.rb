# frozen_string_literal: true

module Integrations
  module Email
    module V1
      class InstructionsController < Integrations::Email::V1::IntegrationsController
        # (GET) Email instructions screen
        # /integrations/email/v1/instructions
        # integrations_email_v1_instructions_path
        # integrations_email_v1_instructions_url
        def show
          render partial: 'integrations/email/v1/js/show', locals: { cards: %w[instructions] }
        end
      end
    end
  end
end

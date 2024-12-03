# frozen_string_literal: true

module Integrations
  module Cardx
    class InstructionsController < Integrations::Cardx::IntegrationsController
      # (GET) CardX instructions screen
      # /integrations/cardx/instructions
      # integrations_cardx_instructions_path
      # integrations_cardx_instructions_url
      def show
        render partial: 'integrations/cardx/js/show', locals: { cards: %w[instructions] }
      end
    end
  end
end

# frozen_string_literal: true

# app/controllers/integrations/servicetitan/instructions_controller.rb
module Integrations
  module Servicetitan
    class InstructionsController < Servicetitan::IntegrationsController
      # (GET) ServiceTitan integration edit screen
      # /integrations/servicetitan/instructions
      # integrations_servicetitan_instructions_path
      # integrations_servicetitan_instructions_url
      def show
        render partial: 'integrations/servicetitan/js/show', locals: { cards: %w[instructions] }
      end
    end
  end
end

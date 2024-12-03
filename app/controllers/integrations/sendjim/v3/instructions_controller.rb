# frozen_string_literal: true

# app/controllers/integrations/sendjim/v3/instructions_controller.rb
module Integrations
  module Sendjim
    module V3
      # support for displaying user instructions for SendJim integration
      class InstructionsController < Sendjim::V3::IntegrationsController
        # (GET) SendJim integration instructions screen
        # /integrations/sendjim/v3/instruction
        # integrations_sendjim_v3_instruction_path
        # integrations_sendjim_v3_instruction_url
        def show
          render partial: 'integrations/sendjim/v3/js/show', locals: { cards: %w[instructions_show] }
        end
      end
    end
  end
end

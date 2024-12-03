# frozen_string_literal: true

# app/controllers/integrations/dope/v1/instructions_controller.rb
module Integrations
  module Dope
    module V1
      # support for displaying user instructions for dope integration
      class InstructionsController < Dope::V1::IntegrationsController
        # (GET) dope integration instructions screen
        # /integrations/dope/v1/instructions
        # integrations_dope_v1_instructions_path
        # integrations_dope_v1_instructions_url
        def show
          render partial: 'integrations/dope/v1/js/show', locals: { cards: %w[instructions_show] }
        end
      end
    end
  end
end

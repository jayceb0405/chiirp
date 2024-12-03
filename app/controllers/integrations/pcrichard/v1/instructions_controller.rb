# frozen_string_literal: true

# app/controllers/integrations/pcrichard/v1/instructions_controller.rb
module Integrations
  module Pcrichard
    module V1
      class InstructionsController < Pcrichard::V1::IntegrationsController
        # (GET) show PC Richard instructions screen
        # /integrations/pcrichard/v1/instructions
        # integrations_pcrichard_v1_instructions_path
        # integrations_pcrichard_v1_instructions_url
        def show
          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[instructions_show] }
        end
      end
    end
  end
end

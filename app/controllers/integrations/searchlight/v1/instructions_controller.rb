# frozen_string_literal: true

# app/controllers/integrations/searchlight/v1/instructions_controller.rb
module Integrations
  module Searchlight
    module V1
      class InstructionsController < Searchlight::V1::IntegrationsController
        # (GET) show SearchLight instructions screen
        # /integrations/searchlight/v1/instructions
        # integrations_searchlight_v1_instructions_path
        # integrations_searchlight_v1_instructions_url
        def show
          render partial: 'integrations/searchlight/v1/js/show', locals: { cards: %w[instructions_show] }
        end
      end
    end
  end
end

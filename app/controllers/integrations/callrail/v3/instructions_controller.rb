# frozen_string_literal: true

module Integrations
  module Callrail
    module V3
      class InstructionsController < Integrations::Callrail::V3::IntegrationsController
        # (GET) CallRail instructions screen
        # /integrations/callrail/v3/instructions
        # integrations_callrail_v3_instructions_path
        # integrations_callrail_v3_instructions_url
        def show
          render partial: 'integrations/callrail/v3/js/show', locals: { cards: %w[instructions] }
        end
      end
    end
  end
end

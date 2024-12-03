# frozen_string_literal: true

# app/controllers/integrations/five9/instructions_controller.rb
module Integrations
  module Five9
    # integration endpoints supporting Five9 integrations instructions
    class InstructionsController < Five9::IntegrationsController
      def show
        # (GET) Five9 integration instruction screen
        # /integrations/five9/instructions
        # integrations_five9_instructions_path
        # integrations_five9_instructions_url
        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %(instructions) } }
          format.html { render 'integrations/five9/edit' }
        end
      end
    end
  end
end

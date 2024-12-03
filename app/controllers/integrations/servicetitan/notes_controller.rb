# frozen_string_literal: true

# app/controllers/integrations/servicetitan/notes_controller.rb
module Integrations
  module Servicetitan
    class NotesController < Servicetitan::IntegrationsController
      # (GET) show ServiceTitan notes processing screen
      # /integrations/servicetitan/notes
      # integrations_servicetitan_notes_path
      # integrations_servicetitan_notes_url
      def show
        render partial: 'integrations/servicetitan/notes/js/show', locals: { cards: %w[show] }
      end

      # (PUT/PATCH) save ServiceTitan notes processing settings
      # /integrations/servicetitan/notes
      # integrations_servicetitan_notes_path
      # integrations_servicetitan_notes_url
      def update
        @client_api_integration.update(notes: params_notes)

        render partial: 'integrations/servicetitan/notes/js/show', locals: { cards: %w[show] }
      end

      private

      def params_notes
        params.permit(:push_notes, :textin, :textout_aiagent, :textout_auto, :textout_manual).to_unsafe_h.transform_values(&:to_bool)
      end
    end
  end
end

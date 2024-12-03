# frozen_string_literal: true

# app/controllers/integrations/five9/lead_sources_controller.rb
module Integrations
  module Five9
    # integration endpoints supporting Five9 lead sources configuration
    class LeadSourcesController < Five9::IntegrationsController
      before_action :client_api_integration

      def edit
        # (GET) edit a List for Five9 integration
        # /integrations/five9/lead_source/edit
        # edit_integrations_five9_lead_source_path
        # edit_integrations_five9_lead_source_url
        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[lead_source_edit] } }
          format.html { redirect_to central_path }
        end
      end

      def update
        # (PUT/PATCH) save List for Five9 integration
        # /integrations/five9/lead_source
        # integrations_five9_lead_source_path
        # integrations_five9_lead_source_url
        lead_sources = params.permit(lead_sources: [])[:lead_sources].map(&:to_i)
        lead_sources.delete(0)
        @client_api_integration.update(lead_sources:)

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[lead_source_edit] } }
          format.html { redirect_to central_path }
        end
      end
    end
  end
end

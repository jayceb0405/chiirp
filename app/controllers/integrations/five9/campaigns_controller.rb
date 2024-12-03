# frozen_string_literal: true

# app/controllers/integrations/five9/campaigns_controller.rb
module Integrations
  module Five9
    # integration endpoints supporting Five9 campaigns configuration
    class CampaignsController < Five9::IntegrationsController
      before_action :client_api_integration
      before_action :client_api_integration_for_servicetitan

      # (GET) edit Campaigns for Five9 integration
      # /integrations/five9/campaigns/edit
      # edit_integrations_five9_campaigns_path
      # edit_integrations_five9_campaigns_url
      def edit
        cards = params.dig(:tbody).to_bool ? %w[campaigns_edit_tbody] : %w[campaigns_edit]

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: } }
          format.html { redirect_to central_path }
        end
      end

      # (PUT/PATCH) save Campaigns for Five9 integration
      # /integrations/five9/campaigns
      # integrations_five9_campaigns_path
      # integrations_five9_campaigns_url
      def update
        @client_api_integration.update(campaigns: params.permit(campaigns: {}).dig(:campaigns))

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[campaigns_edit] } }
          format.html { redirect_to central_path }
        end
      end

      private

      def client_api_integration_for_servicetitan
        return if @client_api_integration.client.integrations_allowed.include?('servicetitan') && (@client_api_integration_for_servicetitan = @client_api_integration.client.client_api_integrations.find_by(target: 'servicetitan', name: ''))

        raise ExceptionHandlers::UserNotAuthorized.new('ServiceTitan Integrations', root_path)
      end
    end
  end
end

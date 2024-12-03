# frozen_string_literal: true

# app/controllers/integrations/servicemonster/push_leads_controller.rb
module Integrations
  module Servicemonster
    # support for configuring actions to push leads to ServiceMonster
    class PushLeadsController < Servicemonster::IntegrationsController
      # (GET) show api_key edit screen
      # /integrations/servicemonster/push_leads/edit
      # edit_integrations_servicemonster_push_leads_path
      # edit_integrations_servicemonster_push_leads_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[push_leads_edit] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      # (PATCH/PUT) update api_key
      # /integrations/servicemonster/push_leads
      # integrations_servicemonster_push_leads_path
      # integrations_servicemonster_push_leads_url
      def update
        @client_api_integration.update(push_leads_tag_id: params_tag_id.dig(:customer, :tag_id).to_i)

        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[push_leads_edit] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      private

      def params_tag_id
        params.require(:push_leads).permit(customer: [:tag_id])
      end
    end
  end
end

# frozen_string_literal: true

# app/controllers/integrations/housecall/push_leads_controller.rb
module Integrations
  module Housecall
    class PushLeadsController < Housecall::IntegrationsController
      # (GET) show api_key edit screen
      # /integrations/housecall/push_leads/edit
      # edit_integrations_housecall_push_leads_path
      # edit_integrations_housecall_push_leads_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[push_leads_edit] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      # (PATCH/PUT) update api_key
      # /integrations/housecall/push_leads
      # integrations_housecall_push_leads_path
      # integrations_housecall_push_leads_url
      def update
        @client_api_integration.update(push_leads_tag_id: params_tag_id.dig(:customer, :tag_id).to_i)

        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[push_leads_edit] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      private

      def params_tag_id
        params.require(:push_leads).permit(customer: [:tag_id])
      end
    end
  end
end

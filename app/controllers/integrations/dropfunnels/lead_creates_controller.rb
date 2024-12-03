# frozen_string_literal: true

# app/controllers/integrations/dropfunnels/lead_creates_controller.rb
module Integrations
  module Dropfunnels
    # DropFunnels integration endpoints supporting lead_create webhook
    class LeadCreatesController < Dropfunnels::IntegrationsController
      def show
        # (GET) show lead_create actions
        # /integrations/dropfunnels/lead_create
        # integrations_dropfunnels_lead_create_path
        # integrations_dropfunnels_lead_create_url
        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[lead_create_show] } }
          format.html { redirect_to root_path }
        end
      end

      def update
        # (PUT/PATCH) save lead_create actions
        # /integrations/dropfunnels/lead_create
        # integrations_dropfunnels_lead_create_path
        # integrations_dropfunnels_lead_create_url
        @client_api_integration.update(params_lead_create)

        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[lead_create_show] } }
          format.html { redirect_to root_path }
        end
      end

      private

      def params_lead_create
        sanitized_params = params.require(:client_api_integration).permit(lead_create: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }])
        sanitized_params[:lead_create][:stop_campaign_ids] = sanitized_params[:lead_create][:stop_campaign_ids]&.compact_blank
        sanitized_params[:lead_create][:stop_campaign_ids] = [0] if sanitized_params[:lead_create][:stop_campaign_ids]&.include?('0')
        sanitized_params
      end
    end
  end
end

# frozen_string_literal: true

# app/controllers/integrations/dropfunnels/two_step_lead_creates_controller.rb
module Integrations
  module Dropfunnels
    # DropFunnels integration endpoints supporting two_step_lead_create webhook
    class TwoStepLeadCreatesController < Dropfunnels::IntegrationsController
      def show
        # (GET) show two_step_lead_create actions
        # /integrations/dropfunnels/two_step_lead_create
        # integrations_dropfunnels_two_step_lead_create_path
        # integrations_dropfunnels_two_step_lead_create_url
        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[two_step_lead_create_show] } }
          format.html { redirect_to root_path }
        end
      end

      def update
        # (PUT/PATCH) save two_step_lead_create actions
        # /integrations/dropfunnels/two_step_lead_create
        # integrations_dropfunnels_two_step_lead_create_path
        # integrations_dropfunnels_two_step_lead_create_url
        @client_api_integration.update(params_two_step_lead_create)

        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[two_step_lead_create_show] } }
          format.html { redirect_to root_path }
        end
      end

      private

      def params_two_step_lead_create
        sanitized_params = params.require(:client_api_integration).permit(two_step_lead_create: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }])
        sanitized_params[:two_step_lead_create][:stop_campaign_ids] = sanitized_params[:two_step_lead_create][:stop_campaign_ids]&.compact_blank
        sanitized_params[:two_step_lead_create][:stop_campaign_ids] = [0] if sanitized_params[:two_step_lead_create][:stop_campaign_ids]&.include?('0')
        sanitized_params
      end
    end
  end
end

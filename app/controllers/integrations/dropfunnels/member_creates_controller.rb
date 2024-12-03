# frozen_string_literal: true

# app/controllers/integrations/dropfunnels/member_creates_controller.rb
module Integrations
  module Dropfunnels
    # DropFunnels integration endpoints supporting member_create webhook
    class MemberCreatesController < Dropfunnels::IntegrationsController
      def show
        # (GET) show member_create actions
        # /integrations/dropfunnels/member_create
        # integrations_dropfunnels_member_create_path
        # integrations_dropfunnels_member_create_url
        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[member_create_show] } }
          format.html { redirect_to root_path }
        end
      end

      def update
        # (PUT/PATCH) save member_create actions
        # /integrations/dropfunnels/member_create
        # integrations_dropfunnels_member_create_path
        # integrations_dropfunnels_member_create_url
        @client_api_integration.update(params_member_create)

        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[member_create_show] } }
          format.html { redirect_to root_path }
        end
      end

      private

      def params_member_create
        sanitized_params = params.require(:client_api_integration).permit(member_create: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }])
        sanitized_params[:member_create][:stop_campaign_ids] = sanitized_params[:member_create][:stop_campaign_ids]&.compact_blank
        sanitized_params[:member_create][:stop_campaign_ids] = [0] if sanitized_params[:member_create][:stop_campaign_ids]&.include?('0')
        sanitized_params
      end
    end
  end
end

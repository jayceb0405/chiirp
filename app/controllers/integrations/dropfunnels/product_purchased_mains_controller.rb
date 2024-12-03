# frozen_string_literal: true

# app/controllers/integrations/dropfunnels/product_purchased_mains_controller.rb
module Integrations
  module Dropfunnels
    # DropFunnels integration endpoints supporting product_purchased_main webhook
    class ProductPurchasedMainsController < Dropfunnels::IntegrationsController
      def show
        # (GET) show product_purchased_main actions
        # /integrations/dropfunnels/product_purchased_main
        # integrations_dropfunnels_product_purchased_main_path
        # integrations_dropfunnels_product_purchased_main_url
        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[product_purchased_main_show] } }
          format.html { redirect_to root_path }
        end
      end

      def update
        # (PUT/PATCH) save product_purchased_main actions
        # /integrations/dropfunnels/product_purchased_main
        # integrations_dropfunnels_product_purchased_main_path
        # integrations_dropfunnels_product_purchased_main_url
        @client_api_integration.update(params_product_purchased_main)

        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[product_purchased_main_show] } }
          format.html { redirect_to root_path }
        end
      end

      private

      def params_product_purchased_main
        sanitized_params = params.require(:client_api_integration).permit(product_purchased_main: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }])
        sanitized_params[:product_purchased_main][:stop_campaign_ids] = sanitized_params[:product_purchased_main][:stop_campaign_ids]&.compact_blank
        sanitized_params[:product_purchased_main][:stop_campaign_ids] = [0] if sanitized_params[:product_purchased_main][:stop_campaign_ids]&.include?('0')
        sanitized_params
      end
    end
  end
end

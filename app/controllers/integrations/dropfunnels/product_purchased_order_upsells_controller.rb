# frozen_string_literal: true

# app/controllers/integrations/dropfunnels/product_purchased_order_upsells_controller.rb
module Integrations
  module Dropfunnels
    # DropFunnels integration endpoints supporting product_purchased_order_upsell webhook
    class ProductPurchasedOrderUpsellsController < Dropfunnels::IntegrationsController
      def show
        # (GET) show product_purchased_order_upsell actions
        # /integrations/dropfunnels/product_purchased_order_upsell
        # integrations_dropfunnels_product_purchased_order_upsell_path
        # integrations_dropfunnels_product_purchased_order_upsell_url
        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[product_purchased_order_upsell_show] } }
          format.html { redirect_to root_path }
        end
      end

      def update
        # (PUT/PATCH) save product_purchased_order_upsell actions
        # /integrations/dropfunnels/product_purchased_order_upsell
        # integrations_dropfunnels_product_purchased_order_upsell_path
        # integrations_dropfunnels_product_purchased_order_upsell_url
        @client_api_integration.update(params_product_purchased_order_upsell)

        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[product_purchased_order_upsell_show] } }
          format.html { redirect_to root_path }
        end
      end

      private

      def params_product_purchased_order_upsell
        sanitized_params = params.require(:client_api_integration).permit(product_purchased_order_upsell: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }])
        sanitized_params[:product_purchased_order_upsell][:stop_campaign_ids] = sanitized_params[:product_purchased_order_upsell][:stop_campaign_ids]&.compact_blank
        sanitized_params[:product_purchased_order_upsell][:stop_campaign_ids] = [0] if sanitized_params[:product_purchased_order_upsell][:stop_campaign_ids]&.include?('0')
        sanitized_params
      end
    end
  end
end

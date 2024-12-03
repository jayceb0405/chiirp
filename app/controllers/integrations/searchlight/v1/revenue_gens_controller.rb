# frozen_string_literal: true

# app/controllers/integrations/searchlight/v1/revenue_gens_controller.rb
module Integrations
  module Searchlight
    module V1
      class RevenueGensController < Searchlight::V1::IntegrationsController
        # (GET) show the SearchLight revenue attribution screen
        # /integrations/searchlight/v1/revenue_gen/edit
        # edit_integrations_searchlight_v1_revenue_gen_path
        # edit_integrations_searchlight_v1_revenue_gen_url
        def edit
          render partial: 'integrations/searchlight/v1/js/show', locals: { cards: %w[revenue_gen_edit] }
        end

        # (PATCH/PUT) save the SearchLight revenue attribution settings
        # /integrations/searchlight/v1/revenue_gen
        # integrations_searchlight_v1_revenue_gen_path
        # integrations_searchlight_v1_revenue_gen_url
        def update
          @client_api_integration.update(revenue_gen: params_revenue_gen)

          render partial: 'integrations/searchlight/v1/js/show', locals: { cards: %w[revenue_gen_edit] }
        end

        private

        def params_revenue_gen
          sanitized_params = params.permit(campaign_ids: [])

          sanitized_params[:campaign_ids] = sanitized_params.dig(:campaign_ids)&.compact_blank&.map(&:to_i) || []
          JsonLog.info 'Integrations::Searchlight::V1::RevenueGensController.params_revenue_gen', { sanitized_params: }

          sanitized_params
        end
      end
    end
  end
end

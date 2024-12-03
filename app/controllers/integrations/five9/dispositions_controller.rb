# frozen_string_literal: true

# app/controllers/integrations/five9/dispositions_controller.rb
module Integrations
  module Five9
    # integration endpoints supporting Five9 dispositions configuration
    class DispositionsController < Five9::IntegrationsController
      before_action :client_api_integration

      def edit
        # (GET) edit a Disposition for Five9 integration
        # /integrations/five9/dispositions/:id/edit
        # edit_integrations_five9_disposition_path(:id)
        # edit_integrations_five9_disposition_url(:id)
        disposition_id = params.permit(:id).dig(:id)
        disposition    = @client_api_integration.dispositions.find { |disp| disp['id'] == disposition_id }
        disposition    = { id: disposition_id, name: params.permit(:name).dig(:name).to_s, campaign_id: 0, group_id: 0, tag_id: 0, stage_id: 0 } if disposition.nil?

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[disposition_edit], disposition: disposition.symbolize_keys } }
          format.html { redirect_to central_path }
        end
      end

      def index
        # (GET) list Dispositions for Five9 integration
        # /integrations/five9/dispositions
        # integrations_five9_dispositions_path
        # integrations_five9_dispositions_url
        cards = params.dig(:tbody).to_bool ? %w[disposition_index_tbody] : %w[disposition_index]

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: } }
          format.html { redirect_to central_path }
        end
      end

      def update
        # (PUT/PATCH) save Disposition for Five9 integration
        # /integrations/five9/dispositions/:id
        # integrations_five9_disposition_path(:id)
        # integrations_five9_disposition_url(:id)
        disposition_id     = params.permit(:id).dig(:id)
        disposition_params = params.require(:disposition).permit(:name, :campaign_id, :group_id, :tag_id, :stage_id, stop_campaign_ids: [])
        disposition_params[:stop_campaign_ids] = disposition_params[:stop_campaign_ids]&.compact_blank
        disposition_params[:stop_campaign_ids] = [0] if disposition_params[:stop_campaign_ids]&.include?('0')

        if (disp = @client_api_integration.dispositions.find { |disposition| disposition['id'] == disposition_id })
          @client_api_integration.dispositions.delete(disp)
        end

        disposition = {
          id:                disposition_id,
          name:              disposition_params[:name].to_s,
          campaign_id:       disposition_params[:campaign_id].to_i,
          group_id:          disposition_params[:group_id].to_i,
          tag_id:            disposition_params[:tag_id].to_i,
          stage_id:          disposition_params[:stage_id].to_i,
          stop_campaign_ids: disposition_params[:stop_campaign_ids]
        }
        @client_api_integration.dispositions << disposition
        @client_api_integration.save

        respond_to do |format|
          format.js { render partial: 'integrations/five9/js/show', locals: { cards: %w[disposition_update], disposition: } }
          format.html { redirect_to central_path }
        end
      end
    end
  end
end

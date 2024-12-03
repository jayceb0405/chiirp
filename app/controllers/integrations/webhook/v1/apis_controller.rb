# frozen_string_literal: true

# app/controllers/integrations/webhook/v1/apis_controller.rb
module Integrations
  module Webhook
    module V1
      # integration endpoints supporting Webhook API calls
      class ApisController < ApplicationController
        skip_before_action :verify_authenticity_token
        before_action :webhook_from_token, only: %i[campaigns custom_fields groups stages tags]

        # (GET) return a hash of Campaigns with id's
        # /integrations/webhook/v1/:token/campaigns
        # integrations_webhook_v1_api_campaigns_path(:token)
        # integrations_webhook_v1_api_campaigns_url(:token)
        def campaigns
          render json: ([[0, 'Do Not Start a Campaign']] + Campaign.where(client_id: @webhook.client_id).order(:name).pluck(:id, :name)).to_json
        end

        # (GET) return a hash of ClientCustomFields
        # /integrations/webhook/v1/:token/custom_fields
        # integrations_webhook_v1_api_custom_fields_path(:token)
        # integrations_webhook_v1_api_custom_fields_url(:token)
        def custom_fields
          render json: ClientCustomField.where(client_id: @webhook.client_id).order(:var_name).pluck(:var_var, :var_name, :var_type, :var_options).to_json
        end

        # (GET) return a hash of Groups with id's
        # /integrations/webhook/v1/:token/groups
        # integrations_webhook_v1_api_groups_path(:token)
        # integrations_webhook_v1_api_groups_url(:token)
        def groups
          render json: ([[0, 'Do Not Assign to a Group']] + Group.where(client_id: @webhook.client_id).order(:name).pluck(:id, :name)).to_json
        end

        # (GET) return a hash of Stages with id's
        # /integrations/webhook/v1/:token/stages
        # integrations_webhook_v1_api_stages_path(:token)
        # integrations_webhook_v1_api_stages_url(:token)
        def stages
          render json: ([[0, 'Do Not Assign to a Stage']] + Stage.joins(:stage_parent).where(stage_parent: { client_id: @webhook.client_id }).order(:name).pluck(:id, :name)).to_json
        end

        # (GET) return a hash of Tags with id's
        # /integrations/webhook/v1/:token/tags
        # integrations_webhook_v1_api_tags_path(:token)
        # integrations_webhook_v1_api_tags_url(:token)
        def tags
          render json: ([[0, 'Do Not Apply a Tag']] + Tag.where(client_id: @webhook.client_id).order(:name).pluck(:id, :name)).to_json
        end

        private

        def webhook_from_token
          return if (@webhook = ::Webhook.find_by(token: params.permit(:token).dig(:token).to_s))

          respond_to do |format|
            format.json { render json: { message: 'Invalid Token.', status: 404 } and return false }
            format.html { render plain: 'Invalid Token.', content_type: 'text/plain', layout: false, status: :not_found and return false }
          end
        end
      end
    end
  end
end

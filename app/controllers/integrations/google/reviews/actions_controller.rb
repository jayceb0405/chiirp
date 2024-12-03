# frozen_string_literal: true

# app/controllers/integrations/google/reviews/actions_controller.rb
module Integrations
  module Google
    module Reviews
      class ActionsController < Google::IntegrationsController
        before_action :authorize_user_for_accounts_locations_config!
        # (GET) show Google actions to select from
        # /integrations/google/reviews/actions/edit
        # edit_integrations_google_reviews_actions_path
        # edit_integrations_google_reviews_actions_url
        def edit
          render partial: 'integrations/google/reviews/js/show', locals: { cards: %w[actions_edit] }
        end

        # (POST) show/update Campaigns selected to exclude after a Google review is received
        # /integrations/google/reviews/actions/review_campaigns
        # integrations_google_reviews_actions_review_campaigns_path
        # integrations_google_reviews_actions_review_campaigns_url
        def review_campaigns
          @client_api_integration.update(params_review_campaign_ids_excluded)

          render partial: 'integrations/google/reviews/js/show', locals: { cards: %w[show_review_campaigns_excluded] }
        end

        # (PUT/PATCH) save Google actions selections
        # /integrations/google/reviews/actions
        # integrations_google_reviews_actions_path
        # integrations_google_reviews_actions_url
        def update
          @client_api_integration.update(actions_reviews: params_actions)

          render partial: 'integrations/google/reviews/js/show', locals: { cards: %w[actions_edit] }
        end

        private

        def params_actions
          sanitized_params = params.require(:actions).permit(
            '1': %i[campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }],
            '2': %i[campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }],
            '3': %i[campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }],
            '4': %i[campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }],
            '5': %i[campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }]
          )

          (1..5).each do |stars|
            sanitized_params[stars.to_s.to_sym][:campaign_id]       = sanitized_params[stars.to_s.to_sym][:campaign_id].to_i
            sanitized_params[stars.to_s.to_sym][:group_id]          = sanitized_params[stars.to_s.to_sym][:group_id].to_i
            sanitized_params[stars.to_s.to_sym][:stage_id]          = sanitized_params[stars.to_s.to_sym][:stage_id].to_i
            sanitized_params[stars.to_s.to_sym][:tag_id]            = sanitized_params[stars.to_s.to_sym][:tag_id].to_i
            sanitized_params[stars.to_s.to_sym][:stop_campaign_ids] = sanitized_params[stars.to_s.to_sym][:stop_campaign_ids]&.compact_blank
            sanitized_params[stars.to_s.to_sym][:stop_campaign_ids] = [0] if sanitized_params[stars.to_s.to_sym][:stop_campaign_ids]&.include?('0')
          end

          sanitized_params
        end

        def params_review_campaign_ids_excluded
          sanitized_params = params.permit(review_campaign_ids_excluded: [])

          sanitized_params[:review_campaign_ids_excluded] = sanitized_params.dig(:review_campaign_ids_excluded).compact_blank.map(&:to_i)

          sanitized_params
        end
      end
    end
  end
end

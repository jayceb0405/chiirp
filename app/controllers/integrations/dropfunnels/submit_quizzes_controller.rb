# frozen_string_literal: true

# app/controllers/integrations/dropfunnels/submit_quizzes_controller.rb
module Integrations
  module Dropfunnels
    # DropFunnels integration endpoints supporting submit_quiz webhook
    class SubmitQuizzesController < Dropfunnels::IntegrationsController
      def show
        # (GET) show submit_quiz actions
        # /integrations/dropfunnels/submit_quiz
        # integrations_dropfunnels_submit_quiz_path
        # integrations_dropfunnels_submit_quiz_url
        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[submit_quiz_show] } }
          format.html { redirect_to root_path }
        end
      end

      def update
        # (PUT/PATCH) save submit_quiz actions
        # /integrations/dropfunnels/submit_quiz
        # integrations_dropfunnels_submit_quiz_path
        # integrations_dropfunnels_submit_quiz_url
        @client_api_integration.update(params_submit_quiz)

        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[submit_quiz_show] } }
          format.html { redirect_to root_path }
        end
      end

      private

      def params_submit_quiz
        sanitized_params = params.require(:client_api_integration).permit(submit_quiz: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }])
        sanitized_params[:submit_quiz][:stop_campaign_ids] = sanitized_params[:submit_quiz][:stop_campaign_ids]&.compact_blank
        sanitized_params[:submit_quiz][:stop_campaign_ids] = [0] if sanitized_params[:submit_quiz][:stop_campaign_ids]&.include?('0')
        sanitized_params
      end
    end
  end
end

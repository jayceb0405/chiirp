# frozen_string_literal: true

# app/controllers/integrations/facebook/pages_controller.rb
module Integrations
  module Facebook
    class PagesController < Facebook::IntegrationsController
      # (GET) list all Facebook Page forms
      # /integrations/facebook/pages
      # integrations_facebook_pages_path
      # integrations_facebook_pages_url
      def index; end

      # (GET)
      # /integrations/facebook/pages/:id/page
      # page_integrations_facebook_page_path(:id)
      # page_integrations_facebook_page_url(:id)
      def page
        @fb_page_id = params.permit(:id).dig(:id).to_s
      end

      # (PATCH/PUT) save a Facebook Page form
      # /integrations/facebook/leads/forms/:id
      # integrations_facebook_leads_form_path(:id)
      # integrations_facebook_leads_form_url(:id)
      def update
        form = params_form

        if form.dig('id').present?
          @user_api_integration_leads.forms.delete(@user_api_integration_leads.forms.find { |f| f['id'] == form['id'].to_s })
          @user_api_integration_leads.forms << form
          @user_api_integration_leads.save
        end

        respond_to do |format|
          format.js { render partial: 'integrations/facebook/js/show', locals: { cards: %w[index_forms] } }
          format.html { redirect_to integrations_facebook_integration_path }
        end
      end

      # (GET)
      # /integrations/facebook/pages/:id/user
      # user_integrations_facebook_page_path(:id)
      # user_integrations_facebook_page_url(:id)
      def user
        @fb_user_id = params.permit(:id).dig(:id).to_s
      end

      private

      def params_form
        response = params.include?(:forms) ? params.require(:forms).permit(:id, :page_id, :user_id, :campaign_id, :group_id, :stage_id, :tag_id, questions: {}) : {}

        response.dig(:questions).each do |_question, responses|
          responses.each do |key, value|
            responses[key] = value.to_i unless key.to_s == 'custom_field_id'
          end
        end

        response[:campaign_id] = response.dig(:campaign_id).to_i
        response[:group_id]    = response.dig(:group_id).to_i
        response[:stage_id]    = response.dig(:stage_id).to_i
        response[:tag_id]      = response.dig(:tag_id).to_i

        response
      end
    end
  end
end

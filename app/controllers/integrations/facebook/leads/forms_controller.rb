# frozen_string_literal: true

# app/controllers/integrations/facebook/leads/forms_controller.rb
module Integrations
  module Facebook
    module Leads
      # integration endpoints supporting Facebook leads forms configuration
      class FormsController < Facebook::IntegrationsController
        # (GET) edit a Facebook Page form
        # /integrations/facebook/leads/forms/:id/edit
        # edit_integrations_facebook_leads_form_path(:id)
        # edit_integrations_facebook_leads_form_url(:id)
        def edit
          respond_to do |format|
            format.js { render partial: 'integrations/facebook/js/show', locals: { cards: %w[edit_form], user_id: params.permit(:user_id).dig(:user_id).to_s, page_id: params.permit(:page_id).dig(:page_id).to_s, form_id: params.permit(:id).dig(:id).to_s } }
            format.html { redirect_to integrations_facebook_integration_path }
          end
        end

        # (GET) list all Facebook Page forms
        # /integrations/facebook/leads/forms
        # integrations_facebook_leads_forms_path
        # integrations_facebook_leads_forms_url
        def index
          locals = if params.include?(:user_id)
                     { cards: %w[index_forms_user], user_id: params.permit(:user_id).dig(:user_id).to_s }
                   elsif params.include?(:page_id)
                     { cards: %w[index_forms_page], page_id: params.permit(:page_id).dig(:page_id).to_s }
                   else
                     { cards: %w[index_forms] }
                   end

          respond_to do |format|
            format.js { render partial: 'integrations/facebook/js/show', locals: }
            format.html { redirect_to integrations_facebook_integration_path }
          end
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
end

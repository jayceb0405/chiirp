# frozen_string_literal: true

# app/controllers/integrations/jotform/v2024311/forms_controller.rb
module Integrations
  module Jotform
    module V1
      class FormsController < Jotform::V1::IntegrationsController
        # (GET) match JotForm Page form fields with internal fields
        # /integrations/jotform/v1/forms
        # integrations_jotform_v1_forms_path
        # integrations_jotform_v1_forms_url
        def show; end

        # (PUT/PATCH) match JotForm Page form fields with internal fields
        # /integrations/jotform/v1/forms
        # integrations_jotform_v1_forms_path
        # integrations_jotform_v1_forms_url
        def update
          @user_api_integration.update(jotform_forms: form_params) if params&.include?(:forms)
        end

        private

        def form_params
          form_params = params.require(:forms)
          response = Integrations::JotForm::V1::Base.new(@user_api_integration.api_key, @user_api_integration.jotform_forms).forms

          response.each do |form_id, form|
            response[form_id][:campaign_id] = form_params.dig(form_id, :campaign_id).to_i

            form[:questions].each do |question_id, question|
              if question.dig(:sublabels).empty?
                response[form_id][:questions][question_id][:custom_field_id] = form_params.dig(form_id, question_id, :custom_field_id).to_s

                question[:options].each_key do |option_text|
                  response[form_id][:questions][question_id][:options][option_text] = form_params.dig(form_id, question_id, option_text).to_i
                end
              else

                question[:sublabels].each_key do |var_name|
                  response[form_id][:questions][question_id][:sublabels][var_name][:custom_field_id] = form_params.dig(form_id, question_id, var_name, :custom_field_id).to_s
                end
              end
            end
          end

          response
        end
      end
    end
  end
end

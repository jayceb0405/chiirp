# frozen_string_literal: true

# app/controllers/integrations/pcrichard/v1/model_submissions_controller.rb
module Integrations
  module Pcrichard
    module V1
      class ModelSubmissionsController < Pcrichard::V1::IntegrationsController
        before_action :contact
        # (GET) edit PC Richard model option selections
        # /integrations/pcrichard/v1/models/:contact_id/edit
        # edit_integrations_pcrichard_v1_model_submissions_path(:contact_id)
        # edit_integrations_pcrichard_v1_model_submissions_url(:contact_id)
        def edit
          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[model_submissions_edit] }
        end

        # (PATCH/PUT) update PC Richard model option selections
        # /integrations/pcrichard/v1/models/:contact_id
        # integrations_pcrichard_v1_model_submissions_path(:contact_id)
        # integrations_pcrichard_v1_model_submissions_url(:contact_id)
        def update
          @contact.update_custom_fields(custom_fields: params_models)

          if params.dig(:commit).casecmp?('Save & Submit to PC Richard')
            result = Integration::Pcrichard::V1::Base.new(@client_api_integration).submit_models_to_pc_richard(contact: @contact)

            if result[:success]
              sweetalert_success('Submittal Successful!', 'Data was submitted successfully to PC Richard.', '', { persistent: 'OK' })
            else
              sweetalert_error('Incomplete Submittal!', result[:message], '', { persistent: 'OK' })
            end
          end

          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[model_submissions_edit] }
        end

        private

        def contact
          return if (@contact = @client_api_integration.client.contacts.find_by(id: params.permit(:contact_id)&.dig(:contact_id)))

          render plain: 'not found', content_type: 'text/plain', layout: false, status: :not_found
        end

        def params_models
          params.require(:custom_fields).permit(option_01: {}, option_02: {}, option_03: {}, option_04: {}, option_05: {}, option_06: {}, installation_charge: {}, receipt_notes: {}, internal_notes: {}).values.reduce({}, :merge)
        end
      end
    end
  end
end

# frozen_string_literal: true

# app/controllers/integrations/successware/v202311/push_contacts_controller.rb
module Integrations
  module Successware
    module V202311
      class PushContactsController < Successware::IntegrationsController
        # (DELETE) destroy a Push Lead Tag
        # /integrations/successware/v202311/push_contacts/:id
        # integrations_successware_v202311_push_contact_path(:id)
        # integrations_successware_v202311_push_contact_url(:id)
        def destroy
          @client_api_integration.push_contact_tags.delete(push_contact_tag.deep_stringify_keys)
          @client_api_integration.save

          render partial: 'integrations/successware/v202311/push_contacts/js/show', locals: { cards: %w[push_contacts_index] }
        end

        # (GET) show api_key edit screen
        # /integrations/successware/v202311/push_contacts/:id/edit
        # edit_integrations_successware_v202311_push_contact_path(:id)
        # edit_integrations_successware_v202311_push_contact_url(:id)
        def edit
          @push_contact_tag = push_contact_tag

          render partial: 'integrations/successware/v202311/push_contacts/js/show', locals: { cards: %w[push_contacts_edit] }
        end

        # (GET) display a new Push Contact Tag
        # /integrations/successware/v202311/push_contacts/new
        # new_integrations_successware_v202311_push_contact_path
        # new_integrations_successware_v202311_push_contact_url
        def new
          @push_contact_tag = {
            id:                  SecureRandom.uuid,
            customer_type:       'Residential',
            lead_source_id:      0,
            lead_source_type_id: 0,
            tag_id:              0
          }
          (@client_api_integration.push_contact_tags ||= []) << @push_contact_tag
          @client_api_integration.save

          render partial: 'integrations/successware/v202311/push_contacts/js/show', locals: { cards: %w[push_contacts_new] }
        end

        # (GET) display the list of Push Contacts Tags
        # /integrations/successware/v202311/push_contacts
        # integrations_successware_v202311_push_contacts_path
        # integrations_successware_v202311_push_contacts_url
        def index
          render partial: 'integrations/successware/v202311/push_contacts/js/show', locals: { cards: %w[push_contacts_index] }
        end

        # (PATCH/PUT) update api_key
        # /integrations/successware/v202311/push_contacts/:id
        # integrations_successware_v202311_push_contact_path(:id)
        # integrations_successware_v202311_push_contact_url(:id)
        def update
          # @client_api_integration.update(push_contacts: { customer_tag_id: params_tag_id.dig(:customer, :tag_id).to_i, lead_tag_id: params_tag_id.dig(:lead, :tag_id).to_i })
          @client_api_integration.push_contact_tags.delete(push_contact_tag.deep_stringify_keys)
          @push_contact_tag = params_push_contact_tag
          (@client_api_integration.push_contact_tags ||= []) << @push_contact_tag if @push_contact_tag.present?
          @client_api_integration.save

          render partial: 'integrations/successware/v202311/push_contacts/js/show', locals: { cards: %w[push_contacts_index] }
        end

        private

        def params_push_contact_tag
          return {} unless Integration::Successware::V202311::Base.new(@client_api_integration).valid_credentials?

          sanitized_params = params.require(:push_contact_tag).permit(:tag_id, :customer_type, :lead_source_id)

          sanitized_params[:id]                  = params.permit(:id).dig(:id).to_s
          sanitized_params[:tag_id]              = sanitized_params.dig(:tag_id).to_i
          sanitized_params[:lead_source_id]      = sanitized_params.dig(:lead_source_id).to_i
          sanitized_params[:lead_source_type_id] = Integrations::SuccessWare::V202311::Base.new(@client_api_integration.credentials).lead_source_types.find { |slst| slst.dig(:leadSource).find { |ls| ls.dig(:id).to_i == sanitized_params.dig(:lead_source_id) } }&.dig(:id).to_i

          sanitized_params
        end

        def push_contact_tag
          @client_api_integration.push_contact_tags.map(&:deep_symbolize_keys).find { |pc| pc.dig(:id) == params.permit(:id).dig(:id).to_s }
        end
      end
    end
  end
end

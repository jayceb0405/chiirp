# frozen_string_literal: true

# app/controllers/integrations/servicetitan/push_contacts_controller.rb
module Integrations
  module Servicetitan
    class PushContactsController < Servicetitan::IntegrationsController
      # (DELETE) destroy a Push Lead Tag
      # /integrations/servicetitan/push_contacts/:id
      # integrations_servicetitan_push_contact_path(:id)
      # integrations_servicetitan_push_contact_url(:id)
      def destroy
        @client_api_integration.push_contacts.delete(push_contact.deep_stringify_keys)
        @client_api_integration.save

        render partial: 'integrations/servicetitan/push_contacts/js/show', locals: { cards: %w[push_contacts_index] }
      end

      # (GET) show api_key edit screen
      # /integrations/servicetitan/push_contacts/:id/edit
      # edit_integrations_servicetitan_push_contact_path(:id)
      # edit_integrations_servicetitan_push_contact_url(:id)
      def edit
        @push_contact = push_contact

        render partial: 'integrations/servicetitan/push_contacts/js/show', locals: { cards: %w[push_contacts_edit] }
      end

      # (GET) display a new Push Contact Tag
      # /integrations/servicetitan/push_contacts/new
      # new_integrations_servicetitan_push_contact_path
      # new_integrations_servicetitan_push_contact_url
      def new
        @push_contact = {
          id:               SecureRandom.uuid,
          type:             'Booking',
          customer_type:    'Residential',
          campaign_id:      0,
          business_unit_id: 0,
          job_type_id:      0,
          priority:         'Low',
          tag_id:           0,
          custom_field_id:  0
        }
        (@client_api_integration.push_contacts ||= []) << @push_contact
        @client_api_integration.save

        render partial: 'integrations/servicetitan/push_contacts/js/show', locals: { cards: %w[push_contacts_new] }
      end

      # (GET) display the list of Push Contacts Tags
      # /integrations/servicetitan/push_contacts
      # integrations_servicetitan_push_contacts_path
      # integrations_servicetitan_push_contacts_url
      def index
        render partial: 'integrations/servicetitan/push_contacts/js/show', locals: { cards: %w[push_contacts_index] }
      end

      # (PATCH/PUT) update api_key
      # /integrations/servicetitan/push_contacts/:id
      # integrations_servicetitan_push_contact_path(:id)
      # integrations_servicetitan_push_contact_url(:id)
      def update
        # @client_api_integration.update(push_contacts: { customer_tag_id: params_tag_id.dig(:customer, :tag_id).to_i, lead_tag_id: params_tag_id.dig(:lead, :tag_id).to_i })
        @client_api_integration.push_contacts.delete(push_contact.deep_stringify_keys)
        @push_contact = params_push_contact
        (@client_api_integration.push_contacts ||= []) << @push_contact
        @client_api_integration.save

        render partial: 'integrations/servicetitan/push_contacts/js/show', locals: { cards: %w[push_contacts_index] }
      end

      private

      def params_push_contact
        sanitized_params = params.require(:push_contact).permit(:booking_provider_id, :booking_source, :business_unit_id, :campaign_id, :customer_type, :job_type_id, :priority, :summary_client_custom_field_id, :tag_id, :type)

        sanitized_params[:id]     = params.permit(:id).dig(:id).to_s
        sanitized_params[:tag_id] = sanitized_params.dig(:tag_id).to_i

        if sanitized_params.dig(:type).to_s.casecmp?('customer')
          sanitized_params[:booking_provider_id]             = 0
          sanitized_params[:business_unit_id]                = 0
          sanitized_params[:campaign_id]                     = 0
          sanitized_params[:summary_client_custom_field_id]  = 0
          sanitized_params[:job_type_id]                     = 0
        else
          sanitized_params[:booking_provider_id]             = sanitized_params.dig(:booking_provider_id).to_i
          sanitized_params[:business_unit_id]                = sanitized_params.dig(:business_unit_id).to_i
          sanitized_params[:campaign_id]                     = sanitized_params.dig(:campaign_id).to_i
          sanitized_params[:summary_client_custom_field_id]  = sanitized_params.dig(:summary_client_custom_field_id).to_i
          sanitized_params[:job_type_id]                     = sanitized_params.dig(:job_type_id).to_i
        end

        sanitized_params
      end

      def push_contact
        @client_api_integration.push_contacts.map(&:deep_symbolize_keys).find { |pc| pc.dig(:id) == params.permit(:id).dig(:id).to_s }
      end
    end
  end
end

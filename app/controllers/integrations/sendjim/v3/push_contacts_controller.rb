# frozen_string_literal: true

# app/controllers/integrations/sendjim/v3/push_contacts_controller.rb
module Integrations
  module Sendjim
    module V3
      # support for configuring actions to push Contacts to SendJim
      class PushContactsController < Sendjim::V3::IntegrationsController
        # (DELETE) destroy a Push Contact Tag
        # /integrations/sendjim/v3/push_contacts/:id
        # integrations_sendjim_v3_push_contact_path(:id)
        # integrations_sendjim_v3_push_contact_url(:id)
        def destroy
          @client_api_integration.push_contacts.delete(push_contact.deep_stringify_keys)
          @client_api_integration.save

          render partial: 'integrations/sendjim/v3/js/show', locals: { cards: %w[push_contacts_index] }
        end

        # (GET) show Push Contact edit screen
        # /integrations/sendjim/v3/push_contacts/:id/edit
        # edit_integrations_sendjim_v3_push_contact_path(:id)
        # edit_integrations_sendjim_v3_push_contact_url(:id)
        def edit
          @push_contact = push_contact

          render partial: 'integrations/sendjim/v3/js/show', locals: { cards: %w[push_contacts_edit] }
        end

        # (GET) display a new Push Contact Tag
        # /integrations/sendjim/v3/push_contacts/new
        # new_integrations_sendjim_v3_push_contact_path
        # new_integrations_sendjim_v3_push_contact_url
        def new
          @push_contact = {
            id:              SecureRandom.uuid,
            tag_id:          0,
            send_tags:       true,
            quick_send_id:   0,
            quick_send_type: 'quick_send_mailing'
          }
          (@client_api_integration.push_contacts ||= []) << @push_contact
          @client_api_integration.save

          render partial: 'integrations/sendjim/v3/js/show', locals: { cards: %w[push_contacts_new] }
        end

        # (GET) display the list of Push Contacts Tags
        # /integrations/sendjim/v3/push_contacts
        # integrations_sendjim_v3_push_contacts_path
        # integrations_sendjim_v3_push_contacts_url
        def index
          render partial: 'integrations/sendjim/v3/js/show', locals: { cards: %w[push_contacts_index] }
        end

        # (PATCH/PUT) update Push Contact Tag
        # /integrations/sendjim/v3/push_contacts/:id
        # integrations_sendjim_v3_push_contact_path(:id)
        # integrations_sendjim_v3_push_contact_url(:id)
        def update
          @client_api_integration.push_contacts.delete(push_contact.deep_stringify_keys)
          @push_contact = params_push_contact
          (@client_api_integration.push_contacts ||= []) << @push_contact
          @client_api_integration.save

          render partial: 'integrations/sendjim/v3/js/show', locals: { cards: %w[push_contacts_index] }
        end

        private

        def params_push_contact
          sanitized_params = params.require(:push_contact).permit(:neighbor_count, :quick_send_id, :quick_send_type, :radius, :same_street_only, :send_tags, :tag_id)

          sanitized_params[:id]            = params.permit(:id).dig(:id).to_s
          sanitized_params[:tag_id]        = sanitized_params.dig(:tag_id).to_i
          sanitized_params[:quick_send_id] = sanitized_params.dig(:quick_send_id).to_i
          sanitized_params[:send_tags]     = sanitized_params.dig(:send_tags).to_bool

          if sanitized_params.dig(:quick_send_type).to_s.casecmp?('neighbor_mailing')
            sanitized_params[:neighbor_count]   = sanitized_params.dig(:neighbor_count).to_i
            sanitized_params[:radius]           = sanitized_params[:neighbor_count].positive? ? 0.0 : sanitized_params.dig(:radius).to_f
            sanitized_params[:same_street_only] = sanitized_params.dig(:same_street_only).to_i
          else
            sanitized_params.delete(:neighbor_count)
            sanitized_params.delete(:radius)
            sanitized_params.delete(:same_street_only)
          end
          JsonLog.info 'Integrations::Sendjim::V3::PushContactsController.params_push_contact', { sanitized_params: }

          sanitized_params
        end

        def push_contact
          @client_api_integration.push_contacts.map(&:deep_symbolize_keys).find { |pc| pc.dig(:id) == params.permit(:id).dig(:id).to_s }
        end
      end
    end
  end
end

# frozen_string_literal: true

# app/controllers/integrations/pcrichard/v1/leads_controller.rb
module Integrations
  module Pcrichard
    module V1
      class LeadsController < Pcrichard::V1::IntegrationsController
        before_action :validate_params, only: %i[new]

        # (GET) edit configuration used to receive new PC Richard leads
        # /integrations/pcrichard/v1/leads/edit
        # edit_integrations_pcrichard_v1_leads_path
        # edit_integrations_pcrichard_v1_leads_url
        def edit
          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[leads_edit] }
        end

        # (POST) receive a new PC Richard lead
        # /integrations/pcrichard/v1/leads/new/:api_key
        # integrations_pcrichard_v1_new_leads_path(:api_key)
        # integrations_pcrichard_v1_new_leads_url(:api_key)
        def new
          if (contact = create_new_contact)
            sanitized_params = params_leads_new

            # save params to Contact::RawPosts
            contact.raw_posts.create(ext_source: 'pcrichard', ext_id: 'new_lead', data: params.except(:integration))

            custom_fields = {}
            custom_fields[@client_api_integration.leads['custom_field_assignments']['invoice_number']] = sanitized_params[:invoiceNumber] if sanitized_params.dig(:invoiceNumber) && @client_api_integration.leads.dig('custom_field_assignments', 'invoice_number')
            custom_fields[@client_api_integration.leads['custom_field_assignments']['requested_at']] = sanitized_params[:requestedAt] if sanitized_params.dig(:requestedAt) && @client_api_integration.leads.dig('custom_field_assignments', 'requested_at')
            contact.update_custom_fields(custom_fields:)
            contact.process_actions(
              campaign_id:       @client_api_integration.leads.dig('campaign_id'),
              group_id:          @client_api_integration.leads.dig('group_id'),
              stage_id:          @client_api_integration.leads.dig('stage_id'),
              tag_id:            @client_api_integration.leads.dig('tag_id'),
              stop_campaign_ids: @client_api_integration.leads.dig('stop_campaign_ids')
            )

            render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok
          else
            render plain: 'not found', content_type: 'text/plain', layout: false, status: :not_found
          end
        end

        # (PATCH/PUT) update configuration used to receive new PC Richard leads
        # /integrations/pcrichard/v1/leads
        # integrations_pcrichard_v1_leads_path
        # integrations_pcrichard_v1_leads_url
        def update
          @client_api_integration.update(leads: params_leads_edit, after_recommendations: params_after_recommendations_edit)

          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[leads_edit] }
        end

        private

        def create_new_contact
          sanitized_params = params_leads_new

          if (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, phones: { sanitized_params.dig(:mobilePhone) => 'mobile' }, emails: [], ext_refs: { 'pcrichard' => sanitized_params.dig(:customerId) }))
            contact.update(
              address1:    (sanitized_params.dig(:address01) || contact.address1).to_s,
              address2:    (sanitized_params.dig(:address02) || contact.address2).to_s,
              city:        (sanitized_params.dig(:city) || contact.city).to_s,
              companyname: (sanitized_params.dig(:companyName) || contact.companyname).to_s,
              email:       (sanitized_params.dig(:email) || contact.email).to_s,
              firstname:   (sanitized_params.dig(:firstName) || contact.firstname).to_s,
              lastname:    (sanitized_params.dig(:lastName) || contact.lastname).to_s,
              state:       (sanitized_params.dig(:state) || contact.state).to_s,
              zipcode:     (sanitized_params.dig(:postalCode) || contact.zipcode).to_s,
              sleep:       false
            )
          else
            contact = nil
          end

          contact
        end

        def params_after_recommendations_edit
          sanitized_params = params.require(:after_recommendations).permit(:campaign_id, :group_id, :stage_id, :tag_id, stop_campaign_ids: [])

          sanitized_params[:campaign_id] = sanitized_params.dig(:campaign_id).to_i
          sanitized_params[:group_id]    = sanitized_params.dig(:group_id).to_i
          sanitized_params[:stage_id]    = sanitized_params.dig(:stage_id).to_i
          sanitized_params[:tag_id]      = sanitized_params.dig(:tag_id).to_i
          sanitized_params[:stop_campaign_ids] = sanitized_params.dig(:stop_campaign_ids)&.compact_blank
          sanitized_params[:stop_campaign_ids] = [0] if sanitized_params.dig(:stop_campaign_ids)&.include?('0')

          sanitized_params
        end

        def params_leads_edit
          sanitized_params = params.require(:leads).permit(:campaign_id, :group_id, :stage_id, :tag_id, custom_field_assignments: %i[invoice_number requested_at], stop_campaign_ids: [])

          sanitized_params[:campaign_id] = sanitized_params.dig(:campaign_id).to_i
          sanitized_params[:group_id]    = sanitized_params.dig(:group_id).to_i
          sanitized_params[:stage_id]    = sanitized_params.dig(:stage_id).to_i
          sanitized_params[:tag_id]      = sanitized_params.dig(:tag_id).to_i
          sanitized_params[:stop_campaign_ids] = sanitized_params.dig(:stop_campaign_ids)&.compact_blank
          sanitized_params[:stop_campaign_ids] = [0] if sanitized_params.dig(:stop_campaign_ids)&.include?('0')
          sanitized_params[:custom_field_assignments][:invoice_number] = sanitized_params.dig(:custom_field_assignments, :invoice_number).to_i
          sanitized_params[:custom_field_assignments][:requested_at]   = sanitized_params.dig(:custom_field_assignments, :requested_at).to_i

          sanitized_params
        end

        def params_leads_new
          sanitized_params = params.permit(:address01, :address02, :city, :companyName, :customerId, :email, :firstName, :invoiceNumber, :lastName, :mobilePhone, :postalCode, :requestedAt, :state)

          sanitized_params[:mobilePhone] = sanitized_params.dig(:mobilePhone).to_s.clean_phone(@client_api_integration.client.primary_area_code)

          sanitized_params
        end

        def validate_params
          sanitized_params = params_leads_new
          response         = []

          response << 'Customer ID must be received.' if sanitized_params.dig(:customerId).blank?
          response << 'First Name, Last Name or Company Name must be received.' if sanitized_params.dig(:companyName).blank? && sanitized_params.dig(:firstName).blank? && sanitized_params.dig(:lastName).blank?
          response << 'City must be received.' if sanitized_params.dig(:city).blank?
          response << 'State must be received.' if sanitized_params.dig(:state).blank?
          response << 'Postal Code must be received.' if sanitized_params.dig(:postalCode).blank?
          response << 'Mobile Phone number must be received.' if sanitized_params.dig(:mobilePhone).blank?
          response << 'Invoice number must be received.' if sanitized_params.dig(:invoiceNumber).blank?
          response << 'Valid Date Requested must be received.' unless Time.use_zone('Eastern Time (US & Canada)') { Chronic.parse(sanitized_params.dig(:requestedAt)) }.is_a?(Time)

          return if response.empty?

          respond_to do |format|
            format.json { render json: { message: response.join(', '), status: :not_acceptable } and return false }
            format.js   { render js: response.join(', '), layout: false, status: :not_acceptable and return false }
            format.all  { render response.join(', '), layout: false, status: :not_acceptable, formats: :html and return false }
          end
        end
      end
    end
  end
end

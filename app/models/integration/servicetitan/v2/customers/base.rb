# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/customers.rb
module Integration
  module Servicetitan
    module V2
      module Customers
        module Base
          include Servicetitan::V2::Customers::Imports

          # st_model.update_contact_custom_fields()
          #   (req) contact: Contact
          def update_contact_custom_fields(contact)
            return unless contact.is_a?(Contact) && self.valid_credentials?

            contact_job   = contact.jobs.order(:actual_completed_at, :updated_at).last
            st_technician = nil

            %w[account_balance completion_date customer_type estimate_total ext_tech_name ext_tech_phone job_address job_city job_number job_state job_zip].each do |field|
              if @client_api_integration.custom_field_assignments.dig(field).to_i.positive? && (client_custom_field = @client_api_integration.client.client_custom_fields.find_by(id: @client_api_integration.custom_field_assignments[field].to_i))
                contact_custom_field = contact.contact_custom_fields.find_or_initialize_by(client_custom_field_id: client_custom_field.id)

                var_value = case field
                            when 'account_balance'
                              ContactApiIntegration.find_by(contact_id: contact.id, target: 'servicetitan', name: '')&.account_balance.to_d
                            when 'completion_date'
                              contact_job&.actual_completed_at
                            when 'customer_type'
                              contact_job&.customer_type
                            when 'estimate_total'
                              contact_job&.estimates&.order(total_amount: :desc)&.first&.total_amount.to_d
                            when 'ext_tech_name'
                              st_technician ||= contact_job&.technician
                              "#{st_technician&.dig(:firstname)} #{st_technician&.dig(:lastname)}".strip
                            when 'ext_tech_phone'
                              st_technician ||= contact_job&.technician
                              st_technician&.dig(:phone)&.clean_phone(contact.client.primary_area_code)
                            when 'job_address'
                              [contact_job&.address_01, contact_job&.address_02].compact_blank.join(', ')
                            when 'job_city'
                              contact_job&.city
                            when 'job_number'
                              contact_job&.invoice_number
                            when 'job_state'
                              contact_job&.state
                            when 'job_zip'
                              contact_job&.postal_code
                            end

                contact_custom_field.update(var_value:) unless var_value.nil?
              end
            end
          end

          # receive JSON Customer data and update/create Contact
          # st_model.update_contact_from_customer()
          #   (opt) ignore_email_in_search: (Boolean / default: false)
          #   (req) st_customer_model:      (Hash / ServiceTitan Customer Model)
          #   (opt) st_membership_models:   (Array / ServiceTitan Membership Models for this Contact)
          def update_contact_from_customer(st_customer_model:, st_membership_models: [], ignore_email_in_search: false)
            Rails.logger.info "Integration::Servicetitan::V2::Customers::Base.update_contact_from_customer: #{{ st_customer_model:, st_membership_models: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
            return unless (st_customer_model.is_a?(Hash) || st_customer_model.is_a?(ActionController::Parameters)) && self.valid_credentials?

            @st_client.parse_customer(st_customer_model:)

            return unless @st_client.success? &&
                          (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, phones: @st_client.result[:phones], emails: ignore_email_in_search ? nil : @st_client.result.dig(:contact, :email).to_s, ext_refs: { 'servicetitan' => @st_client.result.dig(:contact, :ext_ref_id).to_s }))

            contact.lastname  = @st_client.result.dig(:contact, :lastname) if contact.lastname.blank? || (@st_client.result.dig(:contact, :lastname).present? && !@st_client.result.dig(:contact, :lastname).casecmp?('friend'))
            contact.firstname = @st_client.result.dig(:contact, :firstname) if contact.firstname.blank? || (@st_client.result.dig(:contact, :firstname).present? && !@st_client.result.dig(:contact, :firstname).casecmp?('friend'))
            contact.address1  = @st_client.result.dig(:contact, :address1) if contact.address1.blank? && @st_client.result.dig(:contact, :address1).present?
            contact.city      = @st_client.result.dig(:contact, :city) if contact.city.blank? && @st_client.result.dig(:contact, :city).present?
            contact.state     = @st_client.result.dig(:contact, :state) if contact.state.blank? && @st_client.result.dig(:contact, :state).present?
            contact.zipcode   = @st_client.result.dig(:contact, :zipcode) if contact.zipcode.blank? && @st_client.result.dig(:contact, :zipcode).present?
            contact.email     = @st_client.result.dig(:contact, :email) if contact.email.blank? && @st_client.result.dig(:contact, :email).present?
            contact.ok2email  = @st_client.result.dig(:contact, :ok2email)
            contact.ok2text   = @st_client.result.dig(:contact, :ok2text)

            if contact.save
              if @st_client.result[:phones]&.keys&.exclude?(contact.primary_phone&.phone) && (new_primary_phone = contact.contact_phones.find_by(phone: @st_client.result[:phones].keys.first))
                new_primary_phone.update(primary: true)
              end

              Contacts::Tags::ApplyByNameJob.perform_now(
                contact_id: contact.id,
                tag_name:   st_customer_model.dig(:type)
              )

              st_membership_models.each { |membership| Contacts::Tags::ApplyByNameJob.perform_now(contact_id: contact.id, tag_name: "Member: #{membership_type_name(membership[:id])}") } if st_membership_models.present?

              self.update_customer_custom_fields(st_customer_model.dig(:customFields))
              self.update_contact_custom_fields(contact)
            else
              Rails.logger.info "Integration::Servicetitan::V2::Customers::Base.update_contact_from_customer: #{{ errors: contact.errors.full_messages }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
            end

            contact
          end

          # update ClientApiIntegration.customer_custom_fields from ServiceTitan customer model
          # st_model.update_customer_custom_fields()
          #   (req) custom_fields: (Array)
          def update_customer_custom_fields(custom_fields)
            Rails.logger.info "Integration::Servicetitan::V2::Customers::Base.update_customer_custom_fields: #{{ custom_fields: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
            return unless custom_fields.is_a?(Array) && custom_fields.present?

            @client_api_integration.customer_custom_fields = @client_api_integration.customer_custom_fields.presence || {}
            custom_fields.each { |custom_field| @client_api_integration.customer_custom_fields[custom_field.dig(:typeId).to_s] = custom_field.dig(:name).to_s }

            @client_api_integration.save
          end
        end
      end
    end
  end
end

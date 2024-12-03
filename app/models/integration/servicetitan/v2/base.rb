# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/base.rb
module Integration
  module Servicetitan
    module V2
      class Base
        attr_reader :error, :message, :result, :success
        alias success? success

        include Servicetitan::V2::BusinessUnits
        include Servicetitan::V2::Calls::Base
        include Servicetitan::V2::Customers::Base
        include Servicetitan::V2::Employees
        include Servicetitan::V2::Estimates
        include Servicetitan::V2::Jobs::Base
        include Servicetitan::V2::Marketing::Base
        include Servicetitan::V2::Memberships::Base
        include Servicetitan::V2::Payments::Base
        include Servicetitan::V2::Pricebook::Base
        include Servicetitan::V2::ReferencesDestroyed
        include Servicetitan::V2::Reports::Base
        include Servicetitan::V2::Tags
        include Servicetitan::V2::Technicians

        EVENT_TYPE_OPTIONS = [
          ['Call Completed', 'call_completed'],
          %w[Estimate estimate],
          ['Job Scheduled', 'job_scheduled'],
          ['Job Rescheduled', 'job_rescheduled'],
          ['Job Status Changed', 'job_status_changed'],
          ['Job Complete', 'job_complete'],
          ['Technician Dispatched', 'technician_dispatched'],
          ['Membership Service Event', 'membership_service_event'],
          ['Membership Expiration', 'membership_expiration']
        ].freeze

        # client_id = xx
        # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'servicetitan', name: ''); st_model = Integration::Servicetitan::V2::Base.new(client_api_integration); st_model.valid_credentials?; st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials)

        # st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)
        #   (req) client_api_integration: (ClientApiIntegration)
        def initialize(client_api_integration = nil)
          reset_attributes
          self.client_api_integration = client_api_integration
        end

        def credentials_exist?
          @st_client.credentials_valid? && @st_client.credentials_client_id_valid? && @st_client.credentials_client_secret_valid?
        end

        def import_block_count
          50
        end

        def jsonlog_with_raw_post(method_description:, raw_post:, contact:, data:)
          return unless data.to_json.length >= 9_700

          JsonLog.info(method_description, {
                         url:        Rails.application.routes.url_helpers.raw_post_url(raw_post, host: I18n.t("tenant.#{Rails.env}.app_host", protocol: I18n.t('tenant.app_protocol'))),
                         id:         data.dig(:id),
                         status:     data.dig(:status),
                         api_key:    data.dig(:api_key),
                         webhook:    data.dig(:webhook),
                         customer:   data.dig(:customer),
                         eventInfo:  data.dig(:__eventInfo),
                         tenantInfo: data.dig(:__tenantInfo)
                       }, client_id: contact.client_id, contact_id: contact.id)
        end

        # push Contact to ServiceTitan as a Booking, Customer or Lead
        # st_model.push_contact_to_servicetitan(contact: Contact, type: String)
        def push_contact_to_servicetitan(args = {})
          contact      = args.dig(:contact)
          type         = args.dig(:type).to_s.downcase
          push_contact = args.dig(:push_contact)

          unless contact.is_a?(Contact) && %w[booking customer lead].include?(type) && push_contact.present? && self.valid_credentials?
            JsonLog.info 'Integration::Servicetitan::V2::Base.push_contact_to_servicetitan', { args:, credentials: self.valid_credentials? }
            return
          end

          case type
          when 'booking'
            @st_client.new_booking(
              fullname:                      contact.fullname,
              address_01:                    contact.address1,
              address_02:                    contact.address2,
              city:                          contact.city,
              state:                         contact.state,
              postal_code:                   contact.zipcode,
              email:                         contact.email,
              phone_numbers:                 contact.contact_phones.pluck(:label, :phone),
              booking_provider_id:           push_contact.dig(:booking_provider_id),
              customer_type:                 push_contact.dig(:customer_type),
              new_client:                    contact.ext_references.find_by(target: 'servicetitan').blank?,
              servicetitan_business_unit_id: push_contact.dig(:business_unit_id),
              servicetitan_campaign_id:      push_contact.dig(:campaign_id),
              servicetitan_job_type_id:      push_contact.dig(:job_type_id),
              servicetitan_priority:         push_contact.dig(:priority),
              source:                        push_contact.dig(:booking_source),
              summary:                       contact.contact_custom_fields.find_by(client_custom_field_id: push_contact.dig(:summary_client_custom_field_id).to_i)&.var_value
            )
          when 'customer'

            if (contact_ext_reference = contact.ext_references.find_by(target: 'servicetitan')) && contact_ext_reference.ext_id.present?
              @st_client.update_customer(
                customer_id:   contact_ext_reference.ext_id,
                firstname:     contact.firstname,
                lastname:      contact.lastname,
                address1:      contact.address1,
                address2:      contact.address2,
                city:          contact.city,
                state:         contact.state,
                zipcode:       contact.zipcode,
                email:         contact.email,
                ok2email:      contact.ok2email.to_i == 1,
                phone_numbers: contact.contact_phones.pluck(:label, :phone),
                customer_type: push_contact.dig(:customer_type)
              )
            else
              @st_client.new_customer(
                firstname:     contact.firstname,
                lastname:      contact.lastname,
                address1:      contact.address1,
                address2:      contact.address2,
                city:          contact.city,
                state:         contact.state,
                zipcode:       contact.zipcode,
                email:         contact.email,
                ok2email:      contact.ok2email.to_i == 1,
                phone_numbers: contact.contact_phones.pluck(:label, :phone),
                customer_type: push_contact.dig(:customer_type)
              )

              if @st_client.success?
                contact_ext_reference = contact.ext_references.find_or_initialize_by(target: 'servicetitan')
                contact_ext_reference.update(ext_id: @st_client.result.dig(:customer_id).to_s) unless @st_client.result.dig(:customer_id).to_s.to_i.zero?
              end
            end
          end
        end

        # send a new note to ServiceTitan for a Contact
        # st_model.send_note()
        # Integration::Servicetitan::V2::Base.new(client_api_integration).send_note()
        #   (req) st_customer_id: (Integer)
        #   (req) content:        (String)
        def send_note(st_customer_id:, content:)
          return unless self.valid_credentials?

          @st_client.new_note(st_customer_id:, content:)
        end

        # update ContactApiIntegration based on the ServiceTitan Customer Model
        # st_model.update_contact_api_integration()
        #   (req) contact:                (Contact)
        #   (req) event_params:           (Hash / ServiceTitan event params)
        def update_contact_api_integration(contact, event_params)
          JsonLog.info 'Integration::Servicetitan::V2::Base.update_contact_api_integration', { event_params:, contact: }, contact_id: contact&.id
          return nil unless contact.is_a?(Contact) && event_params.is_a?(Hash) &&
                            (contact_api_integration = ContactApiIntegration.find_or_initialize_by(contact_id: contact.id, target: 'servicetitan', name: '')) &&
                            self.valid_credentials?

          @st_client.parse_contact_api_integration(event_params)

          return nil unless @st_client.success?

          previous_account_balance = contact_api_integration.account_balance.to_d

          contact_api_integration.update(
            account_balance:            @st_client.result.dig(:account_balance).to_d,
            history_item_ids:           self.updated_history_item_ids(event_params.dig(:historyItemId), contact_api_integration.history_item_ids),
            update_balance_window_days: if @client_api_integration.update_balance_actions.dig('update_balance_window_days') && event_params.dig(:completedOn).present?
                                          # set ContactApiIntegration update_balance_window_days a maximum of ClientApiIntegration update_balance_window_days
                                          [(@client_api_integration.update_balance_actions['update_balance_window_days'] - ((Time.current - Chronic.parse(event_params[:completedOn])) / 86_400).to_i), 0].max
                                        else
                                          0
                                        end
          )

          Integrations::Servicetitan::V2::Customers::Balance::BalanceActionsJob.perform_later(
            client_id:                contact.client_id,
            contact_id:               contact.id,
            previous_account_balance:,
            current_account_balance:  contact_api_integration.account_balance.to_d
          )

          contact_api_integration
        end

        # update Contact data from a TechnicianDispatch webhook
        # st_model.update_contact_from_technician_dispatched_webhook()
        #   (opt) technician_dispatched_params: (Hash)
        def update_contact_from_technician_dispatched_webhook(technician_dispatched_params)
          method_description = 'Integration::Servicetitan::V2::Base.update_contact_from_technician_dispatched_webhook'
          valid_credentials  = self.valid_credentials?
          JsonLog.info method_description, { technician_dispatched_params_class: technician_dispatched_params.class, valid_credentials: }
          return unless (technician_dispatched_params.is_a?(Hash) || technician_dispatched_params.is_a?(ActionController::Parameters)) && valid_credentials

          technician_dispatched_params = technician_dispatched_params.deep_symbolize_keys

          @st_client.parse_customer(st_customer_model: technician_dispatched_params.dig(:customer))

          contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, phones: @st_client.result[:phones], ext_refs: { 'servicetitan' => @st_client.result[:customer_id] })
          JsonLog.info method_description, { st_client_success: @st_client.success?, contact: }
          return unless @st_client.success? && contact

          if contact.update(@st_client.result[:contact])
            contact_api_integration = self.update_contact_api_integration(contact, technician_dispatched_params)

            # save/update Contact::Job after saving raw posts
            contact_job_id = self.update_contact_job_from_webhook(contact, technician_dispatched_params).dig(:contact_job)&.id

            self.update_contact_custom_fields(contact)
            self.apply_servicetitan_tags(contact, technician_dispatched_params.dig(:tags))

            if self.duplicate_webhook?(technician_dispatched_params.dig(:historyItemId), contact_api_integration)
              JsonLog.info method_description, { duplicate_webhook: true }
              return
            end

            # save params to Contact::RawPosts
            raw_post = contact.raw_posts.create(ext_source: 'servicetitan', ext_id: 'techniciandispatched', data: technician_dispatched_params)
            jsonlog_with_raw_post(method_description:, raw_post:, contact:, data: technician_dispatched_params)

            Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.perform_later(
              contact_id:       contact.id,
              action_type:      'technician_dispatched',
              business_unit_id: technician_dispatched_params.dig(:businessUnit, :id),
              contact_job_id:,
              customer_type:    technician_dispatched_params.dig(:customer, :type),
              ext_tag_ids:      self.tag_names_to_ids((technician_dispatched_params.dig(:tags)&.map { |t| t[:name] } || [])),
              ext_tech_id:      @st_client.parse_ext_tech_id_from_job_assignments_model(technician_dispatched_params.dig(:jobAssignments)),
              job_type_id:      technician_dispatched_params.dig(:type, :id),
              membership:       technician_dispatched_params.dig(:customer, :hasActiveMembership),
              total_amount:     technician_dispatched_params.dig(:invoice, :total)
            )
          else
            JsonLog.info method_description, { errors: contact.errors.full_messages }
          end
        end

        # validate the access_token & refresh if necessary
        # st_model.valid_credentials?
        def valid_credentials?
          if credentials_exist? && @st_client.access_token_valid?
            true
          else
            @st_client.update_access_token

            if @st_client.success?
              @client_api_integration.update(credentials: @client_api_integration.credentials.merge({ access_token: @st_client.result.dig(:access_token).to_s, access_token_expires: @st_client.result.dig(:expires).to_i }))
              @st_client = Integrations::ServiceTitan::Base.new(@client_api_integration.credentials)
              true
            else
              JsonLog.info 'Integration::Servicetitan::V2::Base.valid_credentials?', { invalid: true, message: @st_client.message, client_name: @client_api_integration&.client&.name }, client_id: @client_api_integration&.client_id
              false
            end
          end
        end

        private

        def cleaned_client_api_integration
          @client_api_integration.attributes.merge({ 'data' => @client_api_integration.data.merge({ 'credentials' => @client_api_integration.credentials.except('access_token', 'client_secret') }) })
        end

        def client_api_integration=(client_api_integration)
          @client_api_integration = case client_api_integration
                                    when ClientApiIntegration
                                      client_api_integration
                                    when Integer
                                      ClientApiIntegration.find_by(id: client_api_integration)
                                    else
                                      ClientApiIntegration.new(target: 'servicetitan', name: '')
                                    end

          @client                            = @client_api_integration.client
          @client_api_integration_line_items = nil
          @st_client                         = Integrations::ServiceTitan::Base.new(@client_api_integration.credentials)
        end

        def client_api_integration_line_items
          @client_api_integration_line_items ||= @client_api_integration.client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'line_items')
        end

        def duplicate_webhook?(history_item_id, contact_api_integration)
          contact_api_integration.history_item_ids[history_item_id.to_s.strip].to_i > 1
        end

        def reset_attributes
          @error   = 0
          @message = ''
          @result  = nil
          @success = false
        end

        def update_attributes_from_client
          @error   = @st_client.error
          @message = @st_client.message
          @result  = @st_client.result
          @success = @st_client.success?
        end

        def updated_history_item_ids(history_item_id, history_item_ids)
          if (history_item_id = history_item_id.to_s.strip).present?

            if history_item_ids&.key?(history_item_id)
              history_item_ids[history_item_id] += 1
            else
              history_item_ids = {} unless history_item_ids.is_a?(Hash)
              history_item_ids[history_item_id] = 1
            end
          end

          history_item_ids
        end
      end
    end
  end
end

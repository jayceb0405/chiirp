# frozen_string_literal: true

# app/models/Integration/housecallpro/v1/base.rb
module Integration
  module Housecallpro
    module V1
      class Base
        REQUIRED_CLIENT_CUSTOM_FIELDS = [
          { var_name: 'Housecall Pro Invoice ID', var_var: 'invoice_id_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Invoice ID', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[job id] },
          { var_name: 'Housecall Pro Invoice Number', var_var: 'invoice_number_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Invoice Number', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[job number] },
          { var_name: 'Housecall Pro Invoice Name', var_var: 'invoice_name_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Invoice Name', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[job name] },
          { var_name: 'Housecall Pro Invoice Description', var_var: 'invoice_description_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Invoice Description', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[job description] },
          { var_name: 'Housecall Pro Invoice Total', var_var: 'invoice_total_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Invoice Total', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[job total] },
          { var_name: 'Housecall Pro Invoice Balance', var_var: 'invoice_balance_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Invoice Balance', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[job balance] },
          { var_name: 'Housecall Pro Technician ID', var_var: 'job_technician_id_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Technician ID', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[technician id] },
          { var_name: 'Housecall Pro Technician Name', var_var: 'job_technician_name_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Technician Name', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[technician name] },
          { var_name: 'Housecall Pro Technician Phone', var_var: 'job_technician_phone_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Technician Phone', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[technician phone] },
          { var_name: 'Housecall Pro Technician Email', var_var: 'job_technician_email_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Technician Email', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[technician email] },
          { var_name: 'Housecall Pro Job Scheduled', var_var: 'job_scheduled_start_hcp', var_type: 'date', var_options: {}, var_placeholder: 'Housecall Pro Job Scheduled', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[job scheduled start_at] },
          { var_name: 'Housecall Pro Job Completed', var_var: 'job_completed_hcp', var_type: 'date', var_options: {}, var_placeholder: 'Housecall Pro Job Completed', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[job actual completed_at] },
          { var_name: 'Housecall Pro Job Status', var_var: 'job_status_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Job Status', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[job status] },
          { var_name: 'Housecall Pro Estimate ID', var_var: 'estimate_id_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Estimate ID', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[estimate id] },
          { var_name: 'Housecall Pro Estimate Number', var_var: 'estimate_number_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Estimate Number', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[estimate number] },
          { var_name: 'Housecall Pro Estimate Scheduled', var_var: 'estimate_scheduled_start_hcp', var_type: 'date', var_options: {}, var_placeholder: 'Housecall Pro Estimate Scheduled', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[estimate scheduled start_at] },
          { var_name: 'Housecall Pro Estimate Completed', var_var: 'estimate_completed_hcp', var_type: 'date', var_options: {}, var_placeholder: 'Housecall Pro Estimate Completed', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[estimate actual completed_at] },
          { var_name: 'Housecall Pro Estimate Status', var_var: 'estimate_status_hcp', var_type: 'string', var_options: {}, var_placeholder: 'Housecall Pro Estimate Status', var_important: false, image_is_valid: false, client_custom_field_id: 0, webhook_field: %i[estimate status] }
        ].freeze
        WEBHOOK_EVENTS = [
          { name: 'Job Created', event: 'job.created', description: 'Job created' },
          # { name: 'Job Updated', event: 'job.updated', description: 'Job updated' },
          { name: 'Job Canceled', event: 'job.canceled', description: 'Job canceled' },
          { name: 'Job Completed', event: 'job.completed', description: 'Job completed' },
          { name: 'Job Deleted', event: 'job.deleted', description: 'Job deleted' },
          { name: 'Job On My Way', event: 'job.on_my_way', description: 'Job on my way' },
          { name: 'Job Paid', event: 'job.paid', description: 'Job paid' },
          { name: 'Job Scheduled', event: 'job.scheduled', description: 'Job scheduled' },
          { name: 'Job Started', event: 'job.started', description: 'Job started' },
          { name: 'Job Appointment Scheduled', event: 'job.appointment.scheduled', description: 'Job appointment scheduled' },
          { name: 'Job Appointment Rescheduled', event: 'job.appointment.rescheduled', description: 'Job appointment rescheduled' },
          { name: 'Job Appointment Pros Assigned', event: 'job.appointment.appointment_pros_assigned', description: 'Pros assigned to job appointment' },
          { name: 'Job Appointment Pros Unassigned', event: 'job.appointment.appointment_pros_unassigned', description: 'Pros removed from job appointment' },
          { name: 'Job Appointment Discarded', event: 'job.appointment.appointment_discarded', description: 'Job appointment discarded' },
          { name: 'Customer Created', event: 'customer.created', description: 'Customer created' },
          { name: 'Customer Updated', event: 'customer.updated', description: 'Customer updated' },
          { name: 'Customer Deleted', event: 'customer.deleted', description: 'Customer deleted' },
          { name: 'Estimate Created', event: 'estimate.created', description: 'Estimate created' },
          # { name: 'Estimate Updated', event: 'estimate.updated', description: 'Estimate updated' },
          { name: 'Estimate Scheduled', event: 'estimate.scheduled', description: 'Estimate scheduled' },
          { name: 'Estimate On My Way', event: 'estimate.on_my_way', description: 'Pro set estimate status to on my way' },
          { name: 'Estimate Copied to Job', event: 'estimate.copy_to_job', description: 'Pro created a job from the estimate' },
          { name: 'Estimate Sent', event: 'estimate.sent', description: 'Pro sent the estimate to a customer' },
          { name: 'Estimate Finished', event: 'estimate.completed', description: 'Pro set estimate status to finished' },
          { name: 'Estimate Option Created', event: 'estimate.option.created', description: 'An estimate option was created' },
          { name: 'Estimate Option Approval Status Changed', event: 'estimate.option.approval_status_changed', description: 'Estimate option was approved or declined' }
        ].freeze

        include Housecallpro::V1::Customers
        include Housecallpro::V1::Estimates
        include Housecallpro::V1::Jobs
        include Housecallpro::V1::ReferencesDestroyed
        include Housecallpro::V1::Tags
        include Housecallpro::V1::Technicians

        # client_id = xx
        # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'housecall', name: ''); hcp_model = Integration::Housecallpro::V1::Base.new(client_api_integration); hcp_model.valid_credentials?; hcp_client = Integrations::HousecallPro::Base.new(client_api_integration.credentials)

        # hcp_model = Integration::Housecallpro::V1::Base.new(client_api_integration)
        #   (req) client_api_integration: (ClientApiIntegration)
        def initialize(client_api_integration = nil)
          self.client_api_integration = client_api_integration

          @client     = @client_api_integration.client
          @hcp_client = Integrations::HousecallPro::Base.new(@client_api_integration.credentials)

          self.valid_credentials?
        end

        def approval_status_matches?(event_name, criteria_approval_statuses, event_approval_statuses)
          %w[estimate_sent estimate_option_approval_status_changed].exclude?(event_name.to_s) || criteria_approval_statuses.blank? ||
            (criteria_approval_statuses.include?('approved') && event_approval_statuses.include?('approved')) || (criteria_approval_statuses.include?('pro approved') && event_approval_statuses.include?('pro approved')) ||
            (((criteria_approval_statuses.include?('declined') && event_approval_statuses.include?('declined')) || (criteria_approval_statuses.include?('pro declined') && event_approval_statuses.include?('pro declined'))) && !['approved', 'pro approved', nil].intersect?(event_approval_statuses)) ||
            (criteria_approval_statuses.include?('null') && event_approval_statuses.uniq == [nil])
        end

        # assign a Contact to a User
        # based on ContactApiIntegration.ext_tech_phone
        # hcp_model.assign_contact_to_user(contact_api_integration: ContactApiIntegration)
        def assign_contact_to_user(contact_api_integration:)
          return if contact_api_integration&.ext_tech_phone.blank?

          # reassign Contact to Manager of technician based on OrgUsers
          org_user = nil

          if (user = contact_api_integration.contact.client.users.find_by(phone: contact_api_integration.ext_tech_phone))
            org_user = contact_api_integration.contact.client.org_users.find_by(user_id: user.id)
          else
            org_user = contact_api_integration.contact.client.org_users.find_by(phone: contact_api_integration.ext_tech_phone)
            current_level = org_user&.org_position&.level.to_i - 1

            while org_user&.user_id.to_i.zero? && (org_position = contact_api_integration.contact.client.org_positions.find_by(level: current_level))

              contact_api_integration.contact.client.org_users.where(org_group: org_user.org_group, org_position_id: org_position.id, user_id: [1..Float::INFINITY]).find_each do |test_org_user|
                org_user = test_org_user
              end

              current_level -= 1
            end
          end

          contact_api_integration.contact.update(user_id: org_user.user_id) if org_user&.user_id.to_i.positive?
        end

        # convert Housecall Pro Lead Source and return Chiirp Lead Source
        # hcp_model.convert_hcp_lead_source_id()
        #   (req) hcp_lead_source: (String)
        def convert_hcp_lead_source_id(hcp_lead_source)
          return nil if hcp_lead_source.blank?

          unless (lead_source = @client.lead_sources.find_by(name: hcp_lead_source))
            lead_source = @client.lead_sources.create(name: hcp_lead_source)
          end

          lead_source
        end

        # hcp_model.event_criteria_met?
        #   (req) webhook_event: (Hash)
        #   (req) args:          (Hash) ex: see self.process_actions_for_webhook()
        def event_criteria_met?(contact, webhook_event, args)
          event_name = args.dig(:event).to_s.tr('.', '_').to_sym

          return false unless webhook_event.dig(:active).nil? || webhook_event[:active]
          return false unless new_or_updated_event_match?(event_name, webhook_event.dig(:criteria, :event_new), webhook_event.dig(:criteria, :event_updated), args.dig(:event_new).to_bool)
          return false unless line_items_match?(event_name, webhook_event.dig(:criteria, :line_items), (args.dig(:line_items) || []))
          return false unless tag_ids_include?(webhook_event.dig(:criteria, :tag_ids_include), (args.dig(:tags) || []))
          return false unless tag_ids_exclude?(webhook_event.dig(:criteria, :tag_ids_exclude), (args.dig(:tags) || []))
          return false unless ext_tech_ids_include?(event_name, webhook_event.dig(:criteria, :ext_tech_ids), args.dig(:ext_tech_id))
          return false unless lead_sources_include?(webhook_event.dig(:criteria, :lead_sources), contact.lead_source_id)
          return false unless start_date_updated?(event_name, args.dig(:event_new).to_bool, args.dig(:start_date_updated).to_bool)
          # return false unless tech_updated?(event_name, webhook_event.dig(:criteria, :event_updated), webhook_event.dig(:criteria, :tech_updated), args.dig(:event_new).to_bool, args.dig(:tech_updated).to_bool)
          return false unless approval_status_matches?(event_name, webhook_event.dig(:criteria, :approval_status), (args.dig(:approval_status_array) || []))

          true
        end

        # process event received by webhook or retrieved by API call
        # hcp_model.event_process()
        #   (opt) actions:                   (Hash)
        #   (opt) event:                     (Hash)
        #   (opt) process_events:            (Boolean)
        #   (opt) raw_params:                (Hash)
        def event_process(args = {})
          JsonLog.info 'Integration::Housecallpro::V1::Base.event_process', { args: }

          return nil unless self.valid_credentials?

          # return nil if args.dig(:event, :event).to_s.include?('job.appointment')

          if args.dig(:event, :contact, :customer_id).blank? && args.dig(:event, :job, :id).present? && (hcp_job = @hcp_client.job(args[:event][:job][:id].to_s)).present? && (hcp_customer = @hcp_client.customer(hcp_job.dig(:customer, :id).to_s)).present?
            args[:event][:contact] = @hcp_client.parse_contact_from_webhook(job: { customer: hcp_customer }).merge({ customer_id: hcp_job.dig(:customer, :id).to_s })
            args[:event][:contact_phones] = @hcp_client.parse_phones_from_webhook(job: { customer: hcp_customer })
          end

          contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client.id, phones: args.dig(:event, :contact_phones), emails: args.dig(:event, :contact, :email), ext_refs: { 'housecallpro' => args.dig(:event, :contact, :customer_id) })
          JsonLog.info 'Integration::Housecallpro::V1::Base.event_process', contact_id: contact&.id

          return nil unless contact

          contact.lastname       = (args.dig(:event, :contact, :lastname).presence || contact.lastname).to_s
          contact.firstname      = (args.dig(:event, :contact, :firstname).presence || contact.firstname).to_s
          contact.companyname    = (args.dig(:event, :contact, :companyname).presence || contact.companyname).to_s
          contact.address1       = (args.dig(:event, :address, :address_01).presence || contact.address1).to_s
          contact.address2       = (args.dig(:event, :address, :address_02).presence || contact.address2).to_s
          contact.city           = (args.dig(:event, :address, :city).presence || contact.city).to_s
          contact.state          = (args.dig(:event, :address, :state).presence || contact.state).to_s
          contact.zipcode        = (args.dig(:event, :address, :postal_code).presence || contact.zipcode).to_s
          # HCP has a bug where the toggles for automations don’t always turn them off in HCP. So, their solution was to turn off all notifications in accounts that use Chiirp as well.
          # contact.ok2text        = (args.dig(:event, :contact, :ok2text).presence || 1).to_i
          # contact.ok2email       = (args.dig(:event, :contact, :ok2email).presence || 1).to_i
          contact.lead_source_id = self.convert_hcp_lead_source_id(args.dig(:event, :contact, :lead_source))&.id

          return nil unless contact.save

          @client_api_integration.custom_fields.each do |var_var, client_custom_field_id|
            if client_custom_field_id.positive? && contact.client.client_custom_fields.find_by(id: client_custom_field_id)
              contact_custom_field = contact.contact_custom_fields.find_or_create_by(client_custom_field_id:)

              if (custom_field = REQUIRED_CLIENT_CUSTOM_FIELDS.find { |cf| cf[:var_var] == var_var })
                # evaluating hash "dig" as defined by REQUIRED_CLIENT_CUSTOM_FIELDS hash
                var_value = args.dig(:event)
                custom_field[:webhook_field].each { |wf| var_value = var_value.dig(wf) }
                contact_custom_field.update(var_value: var_value.to_s)
              end
            end
          end

          event_new = if args.dig(:event, :event).split('.')[0].casecmp?('job') && !args.dig(:event, :event).split('.')[1].casecmp?('appointment')
                        contact.raw_posts.where(ext_id: args.dig(:event, :event)).where('data @> ?', { job: { id: args.dig(:event, :job, :id).to_s } }.to_json).none?
                      elsif args.dig(:event, :event).split('.')[0].casecmp?('estimate')
                        contact.raw_posts.where(ext_id: args.dig(:event, :event)).where('data @> ?', { estimate: { id: args.dig(:event, :estimate, :id).to_s } }.to_json).none?
                      elsif args.dig(:event, :event).split('.')[0].casecmp?('customer')
                        contact.raw_posts.where(ext_id: args.dig(:event, :event)).where('data @> ?', { customer: { id: args.dig(:event, :customer, :id).to_s } }.to_json).none?
                      elsif args.dig(:event, :event).split('.')[1].casecmp?('appointment')
                        contact.raw_posts.where(ext_id: args.dig(:event, :event)).where('data @> ?', { appointment: { id: args.dig(:event, :appointment, :id).to_s } }.to_json).none?
                      else
                        true
                      end

          # set the data prior to saving ContactRawPost
          process_actions_data = {
            approval_status_array: [],
            contact_id:            contact.id,
            contact_estimate_id:   0,
            contact_job_id:        0,
            event:                 args.dig(:event, :event),
            event_new:,
            line_items:            [],
            start_date_updated:    false,
            tags:                  args.dig(:event, :tags),
            tech_updated:          false,
            ext_tech_id:           args.dig(:event, :technician, :id).to_s
          }

          contact.raw_posts.create(ext_source: 'housecallpro', ext_id: args.dig(:event, :event), data: args[:raw_params]) if args.dig(:raw_params).present?

          apply_tags_from_webhook(contact, args.dig(:event, :tags))

          case args.dig(:event, :event).split('.')[0].downcase
          when 'estimate'
            if args.dig(:event, :estimate, :id).present? && (contact_estimate = contact.estimates.find_or_initialize_by(ext_source: 'housecallpro', ext_id: args.dig(:event, :estimate, :id).to_s))
              process_actions_data[:tech_updated]          = self.technician_changed?(contact_estimate, args.dig(:event, :technician, :id))
              process_actions_data[:start_date_updated]    = contact_estimate.scheduled_start_at != Chronic.parse(args.dig(:event, :estimate, :scheduled, :start_at).to_s)
              process_actions_data[:approval_status_array] = args.dig(:event, :estimate, :options)&.map { |option| option.dig(:approval_status) } || []
              process_actions_data[:contact_estimate_id]   = contact_estimate.id unless contact_estimate.new_record?

              unless args.dig(:event, :event).split('.')[1].casecmp?('deleted')
                contact_estimate.update(
                  actual_completed_at:      args.dig(:event, :estimate, :actual, :completed_at).present? ? Chronic.parse(args[:event][:estimate][:actual][:completed_at].to_s) : contact_estimate.actual_completed_at,
                  actual_on_my_way_at:      args.dig(:event, :estimate, :actual, :on_my_way_at).present? ? Chronic.parse(args[:event][:estimate][:actual][:on_my_way_at].to_s) : contact_estimate.actual_on_my_way_at,
                  actual_started_at:        args.dig(:event, :estimate, :actual, :started_at).present? ? Chronic.parse(args[:event][:estimate][:actual][:started_at].to_s) : contact_estimate.actual_started_at,
                  address_01:               args.dig(:event, :address, :address_01).to_s,
                  address_02:               args.dig(:event, :address, :address_02).to_s,
                  city:                     args.dig(:event, :address, :city).to_s,
                  country:                  args.dig(:event, :address, :country).to_s,
                  estimate_number:          args.dig(:event, :estimate, :number).to_s,
                  ext_tech_id:              args.dig(:event, :technician, :id).to_s,
                  postal_code:              args.dig(:event, :address, :postal_code).to_s,
                  scheduled_arrival_window: args.dig(:event, :estimate, :scheduled, :arrival_window).to_i,
                  scheduled_end_at:         args.dig(:event, :estimate, :scheduled, :end_at).present? ? Chronic.parse(args[:event][:estimate][:scheduled][:end_at].to_s) : contact_estimate.scheduled_end_at,
                  scheduled_start_at:       args.dig(:event, :estimate, :scheduled, :start_at).present? ? Chronic.parse(args[:event][:estimate][:scheduled][:start_at].to_s) : contact_estimate.scheduled_start_at,
                  state:                    args.dig(:event, :address, :state).to_s,
                  status:                   args.dig(:event, :estimate, :status).to_s
                )

                process_actions_data[:contact_estimate_id] = contact_estimate.id
                current_contact_estimate_options           = contact_estimate.options.pluck(:id)

                (args.dig(:event, :estimate, :options) || []).each do |option|
                  if (contact_estimate_option = contact_estimate.options.find_or_initialize_by(ext_source: 'housecallpro', ext_id: option.dig(:id).to_s))
                    current_contact_estimate_options.delete(contact_estimate_option.id)

                    contact_estimate_option.update(
                      name:          option.dig(:name).to_s,
                      status:        option.dig(:approval_status),
                      option_number: option.dig(:option_number).to_s,
                      total_amount:  option.dig(:total_amount),
                      message:       option.dig(:message).to_s
                    )
                  end
                end

                contact_estimate.options.where(id: current_contact_estimate_options).delete_all if current_contact_estimate_options.present?
              end
            end

          when 'job'
            if !args.dig(:event, :event).split('.')[1].casecmp?('appointment') && args.dig(:event, :job, :id).present? && (contact_job = contact.jobs.find_or_initialize_by(ext_source: 'housecallpro', ext_id: args.dig(:event, :job, :id).to_s))
              process_actions_data[:tech_updated]          = self.technician_changed?(contact_job, args.dig(:event, :technician, :id))
              process_actions_data[:start_date_updated]    = contact_job.scheduled_start_at != Chronic.parse(args.dig(:event, :job, :scheduled, :start_at).to_s)
              process_actions_data[:approval_status_array] = [args.dig(:event, :job, :status)]
              process_actions_data[:line_items]            = @hcp_client.job_line_items(args.dig(:event, :job, :id))&.pluck(:id)
              process_actions_data[:contact_job_id]        = contact_job.id unless contact_job.new_record?

              unless args.dig(:event, :event).split('.')[1].casecmp?('deleted')
                contact_job.update(
                  status:                   args.dig(:event, :job, :status).to_s,
                  description:              args.dig(:event, :job, :description).to_s,
                  address_01:               args.dig(:event, :address, :address_01).to_s,
                  address_02:               args.dig(:event, :address, :address_02).to_s,
                  city:                     args.dig(:event, :address, :city).to_s,
                  state:                    args.dig(:event, :address, :state).to_s,
                  postal_code:              args.dig(:event, :address, :postal_code).to_s,
                  country:                  args.dig(:event, :address, :country).to_s,
                  scheduled_start_at:       args.dig(:event, :job, :scheduled, :start_at).present? ? Chronic.parse(args[:event][:job][:scheduled][:start_at].to_s) : contact_job.scheduled_start_at,
                  scheduled_end_at:         args.dig(:event, :job, :scheduled, :end_at).present? ? Chronic.parse(args[:event][:job][:scheduled][:end_at].to_s) : contact_job.scheduled_end_at,
                  scheduled_arrival_window: args.dig(:event, :job, :scheduled, :arrival_window).to_i,
                  actual_started_at:        args.dig(:event, :job, :actual, :started_at).present? ? Chronic.parse(args[:event][:job][:actual][:started_at].to_s) : contact_job.actual_started_at,
                  actual_completed_at:      args.dig(:event, :job, :actual, :completed_at).present? ? Chronic.parse(args[:event][:job][:actual][:completed_at].to_s) : contact_job.actual_completed_at,
                  actual_on_my_way_at:      args.dig(:event, :job, :actual, :on_my_way_at).present? ? Chronic.parse(args[:event][:job][:actual][:on_my_way_at].to_s) : contact_job.actual_on_my_way_at,
                  total_amount:             args.dig(:event, :job, :total_amount),
                  outstanding_balance:      args.dig(:event, :job, :outstanding_balance),
                  ext_tech_id:              args.dig(:event, :technician, :id).to_s,
                  notes:                    args.dig(:event, :job, :notes).to_s,
                  invoice_number:           args.dig(:event, :job, :invoice_number).to_s
                )

                if args.dig(:event, :job, :original_estimate, :id).present? && (contact_estimate = contact.estimates.find_by(ext_source: 'housecallpro', ext_id: args.dig(:event, :job, :original_estimate, :id).to_s))
                  contact_estimate.update(job_id: contact_job.id)
                end

                process_actions_data[:contact_job_id] = contact_job.id

                Integration::Pcrichard::V1::Base.new(nil).update_scheduled_installation_date(contact:, scheduled_at: contact_job.scheduled_start_at)
                Integration::Pcrichard::V1::Base.new(nil).update_completed_installation_date(contact:, completed_at: contact_job.actual_completed_at)
              end
            elsif args.dig(:event, :event).split('.')[1].casecmp?('appointment') && args.dig(:event, :job, :id).present? && (contact_job = contact.jobs.find_or_initialize_by(ext_source: 'housecallpro', ext_id: args.dig(:event, :job, :id).to_s))
              process_actions_data[:tech_updated]          = self.technician_changed?(contact_job, args.dig(:event, :technician, :id))
              process_actions_data[:start_date_updated]    = contact_job.scheduled_start_at != Chronic.parse(args.dig(:event, :appointment, :start_at).to_s)
              process_actions_data[:line_items]            = @hcp_client.job_line_items(args.dig(:event, :job, :id))&.pluck(:id)
              process_actions_data[:contact_job_id]        = contact_job.id unless contact_job.new_record?

              unless args.dig(:event, :event).split('.')[2].casecmp?('appointment_discarded')
                contact_job.update(
                  scheduled_start_at:       args.dig(:event, :appointment, :start_at).present? ? Chronic.parse(args[:event][:appointment][:start_at].to_s) : contact_job.scheduled_start_at,
                  scheduled_end_at:         args.dig(:event, :appointment, :end_at).present? ? Chronic.parse(args[:event][:appointment][:end_at].to_s) : contact_job.scheduled_end_at,
                  scheduled_arrival_window: args.dig(:event, :appointment, :arrival_window_minutes).to_i
                )

                process_actions_data[:contact_job_id] = contact_job.id

                Integration::Pcrichard::V1::Base.new(nil).update_scheduled_installation_date(contact:, scheduled_at: contact_job.scheduled_start_at)
              end
            end
          end

          JsonLog.info 'Integration::Housecallpro::V1::Base.event_process', { process_actions_data: }

          if args.dig(:process_events).to_bool
            self.delay(
              run_at:              Time.current,
              priority:            DelayedJob.job_priority('process_actions_for_webhook'),
              queue:               DelayedJob.job_queue('process_actions_for_webhook'),
              user_id:             contact.user_id,
              contact_id:          contact.id,
              triggeraction_id:    0,
              contact_campaign_id: 0,
              group_process:       0,
              process:             'process_actions_for_webhook',
              data:                { process_actions_data: }
            ).process_actions_for_webhook(process_actions_data)
          end

          contact.process_actions((args.dig(:actions) || {}).merge({ contact_job_id: process_actions_data.dig(:contact_job_id), contact_estimate_id: process_actions_data.dig(:contact_estimate_id) }))

          contact
        end

        def ext_tech_ids_include?(event_name, criteria_ext_tech_ids, event_ext_tech_id)
          %w[job_created job_canceled job_completed job_deleted job_on_my_way job_paid job_scheduled job_started job_appointment_scheduled job_appointment_rescheduled job_appointment_appointment_pros_assigned job_appointment_appointment_pros_unassigned job_appointment_appointment_discarded estimate_scheduled estimate_on_my_way estimate_copy_to_job estimate_sent estimate_completed estimate_option_created estimate_option_approval_status_changed].exclude?(event_name.to_s) ||
            criteria_ext_tech_ids.blank? || criteria_ext_tech_ids.include?(event_ext_tech_id.to_s)
        end

        def import_block_size
          25
        end

        def lead_sources_include?(criteria_lead_source_ids, event_lead_source_id)
          criteria_lead_source_ids.blank? || criteria_lead_source_ids.include?(event_lead_source_id) || (criteria_lead_source_ids.include?(0) && event_lead_source_id.blank?)
        end

        def line_items_match?(event_name, criteria_line_items, event_line_items)
          %w[job_created job_canceled job_completed job_deleted job_on_my_way job_paid job_scheduled job_started job_appointment_scheduled job_appointment_rescheduled job_appointment_appointment_pros_assigned job_appointment_appointment_pros_unassigned job_appointment_appointment_discarded].exclude?(event_name.to_s) ||
            criteria_line_items.blank? || criteria_line_items.intersect?(event_line_items)
        end

        def new_or_updated_event_match?(event_name, criteria_new, criteria_updated, event_new)
          %w[job_created job_canceled job_completed job_deleted job_on_my_way job_paid job_scheduled job_started job_appointment_rescheduled estimate_scheduled estimate_on_my_way estimate_copy_to_job estimate_sent estimate_completed estimate_option_created estimate_option_approval_status_changed].exclude?(event_name.to_s) ||
            (criteria_new.to_bool && event_new) || (criteria_updated.to_bool && !event_new) || (criteria_new.to_bool && criteria_updated.to_bool)
        end

        # process Campaign, Group, Tag, Stage for incoming Housecall Pro webhook
        # hcp_model.process_actions_for_webhook()
        #   (req) contact_id: (Integer)
        #   (req) event:      (String)
        def process_actions_for_webhook(args)
          JsonLog.info 'Integration::Housecallpro::V1::Base.process_actions_for_webhook', { args: }
          return unless args.dig(:event).to_s.present? && (contact = Contact.find_by(id: args.dig(:contact_id).to_i))

          event_name = args.dig(:event).to_s.tr('.', '_').to_sym

          @client_api_integration.webhooks.deep_symbolize_keys.dig(event_name)&.each do |webhook_event|
            next unless self.event_criteria_met?(contact, webhook_event, args)

            JsonLog.info 'Integration::Housecallpro::V1::Base.process_actions_for_webhook', { webhook_event: }, contact_id: contact.id

            contact.assign_user(@client_api_integration.employees.dig(args.dig(:ext_tech_id).to_s)) if webhook_event.dig(:actions, :assign_user).to_bool && args.dig(:ext_tech_id).to_s.present? && @client_api_integration.employees.dig(args.dig(:ext_tech_id).to_s).present?
            contact.process_actions(
              campaign_id:         webhook_event.dig(:actions, :campaign_id).to_i,
              group_id:            webhook_event.dig(:actions, :group_id).to_i,
              stage_id:            webhook_event.dig(:actions, :stage_id).to_i,
              tag_id:              webhook_event.dig(:actions, :tag_id).to_i,
              stop_campaign_ids:   webhook_event.dig(:actions, :stop_campaign_ids),
              contact_job_id:      args.dig(:contact_job_id).to_i,
              contact_estimate_id: args.dig(:contact_estimate_id).to_i
            )
          end
        end

        def start_date_updated?(event_name, event_new, event_start_date_updated)
          %w[job_scheduled estimate_scheduled job_appointment_rescheduled].exclude?(event_name.to_s) ||
            (event_name.to_s.casecmp?('job_appointment_rescheduled') && event_start_date_updated.to_bool) ||
            (%w[job_scheduled estimate_scheduled].include?(event_name.to_s) && (event_new.to_bool || event_start_date_updated.to_bool))
        end

        def tag_ids_exclude?(criteria_tag_ids, event_tag_names)
          criteria_tag_ids.blank? || !@client.tags.where(id: criteria_tag_ids).pluck(:name).intersect?(event_tag_names)
        end

        def tag_ids_include?(criteria_tag_ids, event_tag_names)
          criteria_tag_ids.blank? || @client.tags.where(id: criteria_tag_ids).pluck(:name).intersect?(event_tag_names)
        end

        # def tech_updated?(event_name, criteria_event_updated, criteria_tech_updated, event_new, event_tech_updated)
        #   %w[job_scheduled estimate_scheduled job_appointment_rescheduled job_appointment_appointment_pros_assigned job_appointment_appointment_pros_unassigned].exclude?(event_name.to_s) ||
        #     (%w[job_appointment_appointment_pros_assigned job_appointment_rescheduled job_appointment_appointment_pros_unassigned].include?(event_name.to_s) && (event_new.to_bool || event_tech_updated.to_bool)) ||
        #     !criteria_event_updated.to_bool || !criteria_tech_updated.to_bool || event_new.to_bool || event_tech_updated.to_bool
        # end

        def technician_changed?(contact_job_estimate, st_technician_id)
          contact_job_estimate.ext_tech_id != st_technician_id.to_s
        end

        # validate the access_token & refresh if necessary
        # hcp_model.valid_credentials?
        def valid_credentials?
          if @hcp_client.access_token_valid?
            true
          else
            @hcp_client.access_token

            if @hcp_client.success?
              @client_api_integration.update(credentials: @hcp_client.result)
              @hcp_client = Integrations::HousecallPro::Base.new(@client_api_integration.credentials)
              true
            else
              JsonLog.info('Integration::Housecallpro::V1::Base.valid_credentials?', { error: 'invalid!', message: @hcp_client.message }, client_id: @client&.id)
              false
            end
          end
        end

        private

        def client_api_integration=(client_api_integration)
          @client_api_integration = case client_api_integration
                                    when ClientApiIntegration
                                      client_api_integration
                                    when Integer
                                      ClientApiIntegration.find_by(id: client_api_integration)
                                    else
                                      ClientApiIntegration.new(target: 'housecall', name: '')
                                    end
        end
      end
    end
  end
end

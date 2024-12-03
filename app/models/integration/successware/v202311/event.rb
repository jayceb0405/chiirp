# frozen_string_literal: true

# app/models/integration/successware/v202311/event.rb
module Integration
  module Successware
    module V202311
      module Event
        # process the event received from Successware
        # jb_event_client.process_webhook()
        #   (req) event:          (String)
        #   (req) job_id:         (String)
        #   (opt) job_no:         (String)
        #   (opt) process_events: (Boolean)
        #   (opt) raw_params:     (Hash)
        #   (opt) tenant_id:      (String)
        #   (req) source_id:      (String)
        def process_webhook(args = {})
          JsonLog.info 'Integration::Successware::V202311::Event.process_webhook', { args:, client_api_integration: @client_api_integration }, client_id: @client.id
          return false unless args.dig(:event).present? && args.dig(:job_id).present? && args.dig(:source_id) && self.valid_credentials?

          @contact_estimate = nil
          @contact_invoice  = nil
          @contact_request  = nil
          @contact_visit    = nil

          return false unless (@successware_job = @sw_client.job(args[:job_id])).presence && (@successware_customer = @sw_client.customer(@successware_job.dig(:serviceAccountId))).presence

          @event = args[:event].to_s

          return false unless (@contact = self.create_or_update_contact)
          return false unless (@contact_job = self.create_or_update_job)

          @event_new = @contact.raw_posts.where(ext_id: args[event]).where('data @> ?', { data: { sourceId: args[:source_id] } }.to_json).none?

          # save params to Contact::RawPosts
          @contact.raw_posts.create(ext_source: 'successware', ext_id: args.dig(:event), data: args[:raw_params]) if args.dig(:raw_params).present?

          self.process_actions_for_event(client_api_integration) if args.dig(:process_events).to_bool

          true
        end
        # example Successware webhook data
        # {
        #   created:               '2024-03-28T13:00:13.000000001',
        #   masterID:              '60074',
        #   companyNo:             '1001',
        #   sourceType:            'call',
        #   sourceID:              '572406300491658636',
        #   processed:             '2024-03-28T13:00:13.000000001',
        #   createdDateWithZone:   '2024-03-28T13:00:13.000000001-04:00[EST5EDT]',
        #   processedDateWithZone: '2024-03-28T13:00:13.000000001-04:00[EST5EDT]',
        #   customerTimeZone:      'EST5EDT',
        #   tenantID:              '211',
        #   addInfo:               {
        #     jobNo:    '201199',
        #     jobID:    '572406293915170188',
        #     progress: 'Dispatched',
        #     jobDept:  null,
        #     msgName:  null
        #   }
        # }

        private

        # create or update a Contact from a Successware customer
        # create_or_update_contact
        def create_or_update_contact
          JsonLog.info 'Integration::Successware::V202311::Event.create_or_update_contact', { successware_customer: @successware_customer }, client_id: @client.id

          phones = phones_from_successware_customer(@successware_customer)

          return nil unless (@contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client.id, phones:, emails: [@successware_customer.dig(:email).to_s].compact_blank, ext_refs: { 'successware' => @successware_customer.dig(:id).to_s }))

          @contact.lastname       = (@successware_customer.dig(:customer, :lastName).presence || @contact.lastname).to_s
          @contact.firstname      = (@successware_customer.dig(:customer, :firstName).presence || @contact.firstname).to_s
          @contact.companyname    = (@successware_customer.dig(:customer, :companyName).presence || @contact.companyname).to_s
          @contact.address1       = (@successware_customer.dig(:serviceLocations)&.first&.dig(:billingAddress, :address1).presence || @contact.address1).to_s
          @contact.address2       = (@successware_customer.dig(:serviceLocations)&.first&.dig(:billingAddress, :address2).presence || @contact.address2).to_s
          @contact.city           = (@successware_customer.dig(:serviceLocations)&.first&.dig(:billingAddress, :city).presence || @contact.city).to_s
          @contact.state          = (@successware_customer.dig(:serviceLocations)&.first&.dig(:billingAddress, :state).presence || @contact.state).to_s
          @contact.zipcode        = (@successware_customer.dig(:serviceLocations)&.first&.dig(:billingAddress, :zipCode).presence || @contact.zipcode).to_s
          @contact.ok2text        = 1 if @contact.new_record?
          @contact.ok2email       = @contact.new_record? && @successware_customer.dig(:customer, :noemail).to_bool ? '0' : @contact.ok2email

          unless @contact.save
            JsonLog.info 'Integration::Successware::V202311::Event.create_or_update_contact', { contact_errors: @contact.errors.full_messages.join(' '), contact_phones: @contact.contact_phones, contact: @contact }, client_id: @client.id
            return nil
          end

          @contact
        end

        # create or update a Contacts::Job from a Successware job
        # create_or_update_job
        def create_or_update_job
          JsonLog.info 'Integration::Successware::V202311::Event.create_or_update_job', { event: @event }, client_id: @client.id

          if @event.casecmp?('canceled')

            if (contact_job = @contact.jobs.find_by(ext_source: 'successware', ext_id: @successware_job.dig(:id)))
              contact_job.update(status: 'destroyed')
            end

            return contact_job
          end

          return nil if (contact_job = @contact.jobs.find_or_initialize_by(ext_source: 'successware', ext_id: @successware_job.dig(:id))).blank?

          contact_job[:location] = @sw_client.job_location(@successware_job.dig(:locationId))

          @start_date_updated = Chronic.parse(@successware_job.dig(:startDate)) != contact_job.scheduled_start_at
          # @tech_updated       = sw_client.result.dig(:visitSchedule, :assignedTo, :nodes)&.first&.dig(:id) != @contact_job.ext_tech_id

          contact_job.update(
            status:              @event.to_s.downcase,
            job_type:            (@successware_job.dig(:jobType) || contact_job.job_type).to_s,
            address_01:          (contact_job.dig(:location, :address1) || contact_job.address_01).to_s,
            address_02:          (contact_job.dig(:location, :address2) || contact_job.address_02).to_s,
            city:                (contact_job.dig(:location, :city) || contact_job.city).to_s,
            state:               (contact_job.dig(:location, :state) || contact_job.state).to_s,
            postal_code:         (contact_job.dig(:location, :zipCode) || contact_job.postal_code).to_s,
            scheduled_start_at:  Chronic.parse(@successware_job.dig(:scheduledFor)) || contact_job.scheduled_start_at,
            actual_started_at:   Chronic.parse(@successware_job.dig(:startDate)) || contact_job.actual_started_at,
            actual_completed_at: Chronic.parse(@successware_job.dig(:endDate)) || contact_job.actual_completed_at,
            customer_type:       (if @successware_customer.dig(:customer, :commercial).blank?
                                    contact_job.customer_type
                                  else
                                    (@successware_customer.dig(:customer, :commercial).to_bool ? 'Commercial' : 'Residential')
                                  end) || contact_job.customer_type,
            total_amount:        @successware_job.dig(:invoices).sum { |l| l.dig(:totalAmount) }.to_d,
            # ext_tech_id:         (sw_client.result.dig(:visitSchedule, :assignedTo, :nodes)&.first&.dig(:id) || contact_job.ext_tech_id).to_s,
            invoice_number:      (@successware_job.dig(:invoices)&.first&.dig(:number) || contact_job.invoice_number).to_s
          )

          # create_or_update_lineitems(contact_job, sw_client.result.dig(:lineItems, :nodes))
          # destroy_deleted_lineitems(contact_job, sw_client.result.dig(:lineItems, :nodes))

          # if sw_client.result.dig(:quote, :id).present? && (contact_estimate = @contact.estimates.find_by(ext_source: 'successware', ext_id: sw_client.result.dig(:quote, :id).to_s))
          #   contact_estimate.update(job_id: contact_job.id)
          # end

          contact_job
        end

        def destroy_deleted_lineitems(job_or_estimate, successware_lineitems)
          (job_or_estimate.lineitems.pluck(:ext_id, :name) - successware_lineitems.filter_map { |lineitem| [lineitem.dig(:linkedProductOrService, :id) || '', lineitem.dig(:description).to_s] }).each do |li|
            job_or_estimate.lineitems.find_by(ext_id: li.first, name: li.second)&.destroy
          end
        end

        # qualify event with criteria & process actions if match
        # process_actions_for_event(client_api_integration)
        #   (req) client_api_integration: (ClientApiIntegration)
        def process_actions_for_event(client_api_integration)
          JsonLog.info 'Integration::Successware::V202311::Event.process_actions_for_event', { event: @event, event_new: @event_new, start_date_updated: @start_date_updated, tech_updated: @tech_updated, contact: @contact, contact_job: @contact_job, contact_estimate: @contact_estimate, contact_visit: @contact_visit, client_api_integration: }, client_id: @client.id
          return unless ok_to_process && client_api_integration.is_a?(ClientApiIntegration)

          client_api_integration.webhooks.dig(@event)&.each do |event|
            event.deep_symbolize_keys!

            next if not_event_new?(event)
            next unless customer_type_matches?(event)
            next unless job_type_matches?(event)
            next if not_event_ext_tech_id_match?(event)
            next unless event_start_date_updated?(event)
            next unless event_tech_updated?(event)

            @contact.assign_user(client_api_integration.employees.dig(@contact_job&.ext_tech_id)) if event.dig(:actions, :assign_user) && @contact_job&.ext_tech_id.present? && client_api_integration.employees.dig(@contact_job&.ext_tech_id).present?
            @contact.process_actions(
              campaign_id:         event.dig(:actions, :campaign_id).to_i,
              group_id:            event.dig(:actions, :group_id).to_i,
              stage_id:            event.dig(:actions, :stage_id).to_i,
              tag_id:              event.dig(:actions, :tag_id).to_i,
              stop_campaign_ids:   event.dig(:actions, :stop_campaign_ids),
              contact_estimate_id: @contact_estimate&.id,
              contact_invoice_id:  @contact_invoice&.id,
              contact_job_id:      @contact_job&.id,
              contact_visit_id:    @contact_visit&.id
            )
          end
        end

        def customer_type_matches?(event)
          event.dig(:criteria, :customer_type).blank? || @contact_job&.customer_type.nil? || event.dig(:criteria, :customer_type).include?(@contact_job&.customer_type)
        end

        def not_event_ext_tech_id_match?(event)
          event.dig(:criteria, :ext_tech_ids).present? && @contact_job&.ext_tech_id.present? && event.dig(:criteria, :ext_tech_ids).exclude?(@contact_job&.ext_tech_id)
        end

        def not_event_new?(event)
          event.dig(:criteria, :event_new) != @event_new && (event.dig(:criteria, :event_updated) != !@event_new)
        end

        def event_start_date_updated?(event)
          %w[rescheduled].exclude?(@event) || event.dig(:criteria, :start_date_updated).to_bool || @start_date_updated
        end

        def event_tech_updated?(event)
          %w[assigned].exclude?(@event) || !event.dig(:criteria, :tech_updated).to_bool || @tech_updated
        end

        def job_type_matches?(event)
          event.dig(:criteria, :job_type).blank? || @contact_job&.job_type.nil? || event.dig(:criteria, :job_type).include?(@contact_job&.job_type)
        end

        # parse phone numbers from Successware customer data
        # self.phones_from_successware_customer()
        #   (req) successware_customer: (Hash)
        def phones_from_successware_customer(successware_customer)
          phones = {}
          phones[successware_customer.dig(:customer, :phoneNumber).to_s.tr('^0-9', '')] = 'mobile'
          phones[successware_customer.dig(:customer, :phone2).to_s.tr('^0-9', '')] = 'mobile'
          phones[successware_customer.dig(:customer, :phone3).to_s.tr('^0-9', '')] = 'mobile'
          phones[successware_customer.dig(:customer, :phone4).to_s.tr('^0-9', '')] = 'mobile'

          phones
        end
      end
    end
  end
end

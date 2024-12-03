# frozen_string_literal: true

# app/models/integration/jobber/V20220915/event.rb
module Integration
  module Jobber
    module V20220915
      class Event < Integration::Jobber::Base
        # params = ActionController::Parameters.new(**)
        # sanitized_params = params.require(:data).permit(webHookEvent: %i[accountId appId itemId occuredAt topic])
        # client_api_integration_ids = ClientApiIntegration.where(target: 'jobber', name: '').where('data @> ?', { account: { id: sanitized_params.dig(:webHookEvent, :accountId) } }.to_json).pluck(:id)
        # data = { client_api_integration_id:, account_id: sanitized_params[:webHookEvent][:accountId], item_id: sanitized_params.dig(:webHookEvent, :itemId), process_events: true, raw_params: params.except(:integration), topic: sanitized_params.dig(:webHookEvent, :topic) }
        # jb_model = Integration::Jobber::V20220915::Event.new(data); Integration::Jobber::V20220915::Base.new(client_api_integration).valid_credentials?; jb_client = Integrations::Jobber::V20220915::Base.new(client_api_integration).credentials)

        # initialize Jobber event
        # jb_event_client = Integration::Jobber::V20220915::Event.new()
        #   (req) client_api_integration_id: (Array)
        #   (req) account_id:                (String)
        #   (req) item_id:                   (String)
        #   (opt) process_events:            (Boolean)
        #   (opt) raw_params:                (Hash)
        #   (req) topic:                     (String)
        def initialize(args = {})
          @account_id             = args.dig(:account_id).to_s
          @account_tags           = args.dig(:account_tags) || []
          @client_api_integration = ClientApiIntegration.find_by(id: args.dig(:client_api_integration_id).to_i)
          @item_id                = args.dig(:item_id).to_s
          @process_events         = args.dig(:process_events).to_bool
          @raw_params             = args.dig(:raw_params)
          @start_date_updated     = args.dig(:start_date_updated).to_bool
          @tech_updated           = args.dig(:tech_updated).to_bool
          topic                   = args.dig(:topic).to_s.downcase
          @event_object           = topic.split('_').first
          @event_action           = topic.split('_').last
          @event_new              = false

          @contact                = nil
          @contact_estimate       = nil
          @contact_invoice        = nil
          @contact_job            = nil
          @contact_request        = nil
          @contact_visit          = nil

          @result                 = self.ok_to_process
        end

        # process the event received from Jobber
        # jb_event_client.process
        def process
          JsonLog.info 'Integration::Jobber::V20220915::Event.process', { account_id: @account_id, item_id: @item_id, event_object: @event_object, event_action: @event_action, client_api_integration: @client_api_integration&.attributes_cleaned }, client_id: @client_api_integration&.client_id, contact_id: @contact&.id
          @result = false
          return @result unless self.ok_to_process

          @contact          = nil
          @contact_estimate = nil
          @contact_invoice  = nil
          @contact_job      = nil
          @contact_request  = nil
          @contact_visit    = nil

          case @event_object
          when 'client'
            self.create_or_update_contact(@item_id)
          when 'request'
            self.create_or_update_request(@item_id)
          when 'quote'
            self.create_or_update_estimate(@item_id)
          when 'job'
            self.create_or_update_job(@item_id)
          when 'invoice'
            self.create_or_update_invoice(@item_id)
          when 'visit'
            self.create_or_update_visit(@item_id)
          when 'app'
            Integration::Jobber::V20220915::Base.new(@client_api_integration).delete_credentials if @event_action == 'disconnect'
          end

          return @result unless @contact

          @event_new = @contact.raw_posts.where(ext_id: "#{@event_object}_#{@event_action}").where('data @> ?', { data: { webHookEvent: { itemId: @item_id } } }.to_json).order(created_at: :desc).none?

          # save params to Contact::RawPosts
          @contact.raw_posts.create(ext_source: 'jobber', ext_id: "#{@event_object}_#{@event_action}", data: @raw_params) if @raw_params.present?

          self.process_actions_for_event
        end

        private

        def ok_to_process
          @client_api_integration.is_a?(ClientApiIntegration) && @account_id.present? && @item_id.present? && @event_object.present? && @event_action.present?
        end

        # create or update a Contact from a Jobber client id
        # create_or_update_contact(jobber_client_id)
        #   (req) jobber_client_id: (String)
        def create_or_update_contact(jobber_client_id)
          JsonLog.info 'Integration::Jobber::V20220915::Event.create_or_update_contact', { jobber_client_id: }, client_id: @client_api_integration&.client_id, contact_id: @contact&.id
          return false unless self.ok_to_process && jobber_client_id.present? &&
                              Integration::Jobber::V20220915::Base.new(@client_api_integration).valid_credentials? && (jb_client = Integrations::JobBer::V20220915::Base.new(@client_api_integration.credentials)) &&
                              jb_client.client(jobber_client_id).present? && jb_client.success?

          phones    = {}
          ok_2_text = 0
          jb_client.result.dig(:phones).each do |p|
            phones[p.dig(:number).to_s.tr('^0-9', '')] = p.dig(:description).to_s
            ok_2_text = 1 if p.dig(:smsAllowed).to_bool
          end

          return false unless (@contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, phones:, emails: jb_client.result.dig(:emails)&.first&.dig(:address).to_s, ext_refs: { 'jobber' => jobber_client_id }))

          @contact.lastname       = (jb_client.result.dig(:lastName) || @contact.lastname).to_s
          @contact.firstname      = (jb_client.result.dig(:firstName) || @contact.firstname).to_s
          @contact.companyname    = (jb_client.result.dig(:companyName) || @contact.companyname).to_s
          @contact.address1       = (jb_client.result.dig(:billingAddress, :street1) || @contact.address1).to_s
          @contact.address2       = (jb_client.result.dig(:billingAddress, :street2) || @contact.address2).to_s
          @contact.city           = (jb_client.result.dig(:billingAddress, :city) || @contact.city).to_s
          @contact.state          = (jb_client.result.dig(:billingAddress, :province) || @contact.state).to_s
          @contact.zipcode        = (jb_client.result.dig(:billingAddress, :postalCode) || @contact.zipcode).to_s
          @contact.ok2text        = ok_2_text if @contact.ok2text.to_i.positive?
          @contact.ok2email       = 1
          @contact.save

          JsonLog.info 'Integration::Jobber::V20220915::Event.create_or_update_contact', { errors: @contact.errors.full_messages, contact_phones: @contact.contact_phones }, client_id: @client_api_integration.client_id, contact_id: @contact.id

          jb_client.result.dig(:tags, :nodes).each do |t|
            if t.dig(:label).present?
              Contacts::Tags::ApplyByNameJob.perform_now(
                contact_id: @contact.id,
                tag_name:   t[:label]
              )
              @account_tags << t[:label]
            end
          end

          true
        end

        # create or update a Contacts::Estimate from a Jobber job
        # create_or_update_estimate(jobber_quote_id)
        #   (req) jobber_quote_id: (String)
        def create_or_update_estimate(jobber_quote_id)
          JsonLog.info 'Integration::Jobber::V20220915::Event.create_or_update_estimate', { jobber_quote_id:, event_action: @event_action }, client_id: @client_api_integration&.client_id, contact_id: @contact&.id
          return false unless self.ok_to_process && jobber_quote_id.present? &&
                              Integration::Jobber::V20220915::Base.new(@client_api_integration).valid_credentials? && (jb_client = Integrations::JobBer::V20220915::Base.new(@client_api_integration.credentials))

          if @event_action == 'destroy'

            if (contact_estimate = Contacts::Estimate.joins(:contact).where(contact: { client_id: @client_api_integration.client_id }).find_by(ext_source: 'jobber', ext_id: jobber_quote_id))
              contact_estimate.update(status: 'destroyed')
              @contact = contact_estimate.contact
            end

            return true
          end

          return false unless jb_client.quote(jobber_quote_id).present? && jb_client.success? && create_or_update_contact(jb_client.result.dig(:client, :id)) &&
                              (@contact_estimate = @contact.estimates.find_or_initialize_by(ext_source: 'jobber', ext_id: jobber_quote_id)).present?

          @contact_estimate.update(
            estimate_number: (jb_client.result.dig(:quoteNumber) || @contact_estimate.estimate_number).to_s,
            status:          (jb_client.result.dig(:quoteStatus) || @contact_estimate.status).to_s.downcase,
            address_01:      (jb_client.result.dig(:property, :address, :street1) || @contact_estimate.address_01).to_s,
            address_02:      (jb_client.result.dig(:property, :address, :street2) || @contact_estimate.address_02).to_s,
            city:            (jb_client.result.dig(:property, :address, :city) || @contact_estimate.city).to_s,
            state:           (jb_client.result.dig(:property, :address, :province) || @contact_estimate.state).to_s,
            postal_code:     (jb_client.result.dig(:property, :address, :postalCode) || @contact_estimate.postal_code).to_s,
            country:         (jb_client.result.dig(:property, :address, :country) || @contact_estimate.country).to_s,
            customer_type:   (if jb_client.result.dig(:client, :isCompany).nil?
                                @contact_estimate.customer_type
                              else
                                (jb_client.result[:client][:isCompany].to_bool ? 'Commercial' : 'Residential')
                              end) || @contact_estimate.customer_type,
            total_amount:    (jb_client.result.dig(:amounts, :total) || @contact_estimate.total_amount).to_d
          )

          create_or_update_lineitems(@contact_estimate, jb_client.result.dig(:lineItems, :nodes))
          destroy_deleted_lineitems(@contact_estimate, jb_client.result.dig(:lineItems, :nodes))

          true
        end

        # create or update a Contacts::Invoice from a Jobber invoice
        # create_or_update_invoice(jobber_invoice_id)
        #   (req) jobber_invoice_id: (String)
        def create_or_update_invoice(jobber_invoice_id)
          JsonLog.info 'Integration::Jobber::V20220915::Event.create_or_update_invoice', { jobber_invoice_id:, event_action: @event_action }, client_id: @client_api_integration&.client_id, contact_id: @contact&.id
          return false unless self.ok_to_process && jobber_invoice_id.present? &&
                              Integration::Jobber::V20220915::Base.new(@client_api_integration).valid_credentials? && (jb_client = Integrations::JobBer::V20220915::Base.new(@client_api_integration.credentials))

          if @event_action == 'destroy'

            if (contact_invoice = Contacts::Invoice.joins(:contact).where(contact: { client_id: @client_api_integration.client_id }).find_by(ext_source: 'jobber', ext_id: jobber_invoice_id))
              contact_invoice.update(status: 'destroyed')
              @contact = contact_invoice.contact
            end

            return true
          end

          return false unless jb_client.invoice(jobber_invoice_id).present? && jb_client.success? && create_or_update_contact(jb_client.result.dig(:client, :id)) &&
                              (@contact_invoice = @contact.invoices.find_or_initialize_by(ext_source: 'jobber', ext_id: jobber_invoice_id)).present?

          create_or_update_job(jb_client.result[:job][:id]) if jb_client.result.dig(:job, :id).present?

          @contact_invoice.update(
            job_id:         @contact_invoice.contact.jobs.find_by(ext_id: jb_client.result.dig(:job, :id)) || @contact_invoice.job_id,
            invoice_number: jb_client.result.dig(:invoiceNumber) || @contact_invoice.invoice_number,
            description:    jb_client.result.dig(:subject) || @contact_invoice.description,
            status:         jb_client.result.dig(:invoiceStatus) || @contact_invoice.status,
            customer_type:  if jb_client.result.dig(:client, :isCompany).nil?
                              @contact_invoice.customer_type
                            else
                              (jb_client.result[:client][:isCompany].to_bool ? 'Commercial' : 'Residential')
                            end,
            total_amount:   (jb_client.result.dig(:amounts, :total) || @contact_invoice.total_amount).to_d,
            total_payments: (jb_client.result.dig(:amounts, :paymentsTotal) || @contact_invoice.total_payments).to_d,
            balance_due:    (jb_client.result.dig(:amounts, :invoiceBalance) || @contact_invoice.balance_due).to_d,
            due_date:       Chronic.parse(jb_client.result.dig(:dueDate)) || @contact_invoice.due_date,
            net:            jb_client.result.dig(:invoiceNet) || @contact_invoice.net
          )

          create_or_update_lineitems(@contact_invoice, jb_client.result.dig(:lineItems, :nodes))
          destroy_deleted_lineitems(@contact_invoice, jb_client.result.dig(:lineItems, :nodes))

          true
        end

        # create or update a Contacts::Job from a Jobber job
        # create_or_update_job(jobber_job_id)
        #   (req) jobber_job_id: (String)
        def create_or_update_job(jobber_job_id)
          JsonLog.info 'Integration::Jobber::V20220915::Event.create_or_update_job', { jobber_job_id:, event_action: @event_action }, client_id: @client_api_integration&.client_id, contact_id: @contact&.id
          return false unless self.ok_to_process && jobber_job_id.present? &&
                              Integration::Jobber::V20220915::Base.new(@client_api_integration).valid_credentials? && (jb_client = Integrations::JobBer::V20220915::Base.new(@client_api_integration.credentials))

          if @event_action == 'destroy'

            if (contact_job = Contacts::Job.joins(:contact).where(contact: { client_id: @client_api_integration.client_id }).find_by(ext_source: 'jobber', ext_id: jobber_job_id))
              contact_job.update(status: 'destroyed')
              @contact = contact_job.contact
            end

            return true
          end

          return false unless jb_client.job(jobber_job_id).present? && jb_client.success? && self.create_or_update_contact(jb_client.result.dig(:client, :id)) &&
                              (@contact_job = @contact.jobs.find_or_initialize_by(ext_source: 'jobber', ext_id: jobber_job_id)).present?

          @start_date_updated = Chronic.parse(jb_client.result.dig(:startAt)) != @contact_job.scheduled_start_at
          @tech_updated       = jb_client.result.dig(:visitSchedule, :assignedTo, :nodes)&.first&.dig(:id) != @contact_job.ext_tech_id

          @contact_job.update(
            status:                            (jb_client.result.dig(:jobStatus) || @contact_job.status).to_s.downcase,
            job_type:                          (jb_client.result.dig(:jobType) || @contact_job.job_type).to_s,
            address_01:                        (jb_client.result.dig(:property, :address, :street1) || @contact_job.address_01).to_s,
            address_02:                        (jb_client.result.dig(:property, :address, :street2) || @contact_job.address_02).to_s,
            city:                              (jb_client.result.dig(:property, :address, :city) || @contact_job.city).to_s,
            state:                             (jb_client.result.dig(:property, :address, :province) || @contact_job.state).to_s,
            postal_code:                       (jb_client.result.dig(:property, :address, :postalCode) || @contact_job.postal_code).to_s,
            country:                           (jb_client.result.dig(:property, :address, :country) || @contact_job.country).to_s,
            scheduled_start_at:                Chronic.parse(jb_client.result.dig(:startAt)) || @contact_job.scheduled_start_at,
            scheduled_end_at:                  Chronic.parse(jb_client.result.dig(:endAt)) || @contact_job.scheduled_end_at,
            scheduled_arrival_window:          (jb_client.result.dig(:arrivalWindow, :duration) || @contact_job.scheduled_arrival_window).to_i,
            scheduled_arrival_window_start_at: Chronic.parse(jb_client.result.dig(:arrivalWindow, :startAt)) || @contact_job.scheduled_arrival_window_start_at,
            scheduled_arrival_window_end_at:   Chronic.parse(jb_client.result.dig(:arrivalWindow, :endAt)) || @contact_job.scheduled_arrival_window_end_at,
            customer_type:                     (if jb_client.result.dig(:client, :isCompany).nil?
                                                  @contact_job.customer_type
                                                else
                                                  (jb_client.result[:client][:isCompany].to_bool ? 'Commercial' : 'Residential')
                                                end) || @contact_job.customer_type,
            total_amount:                      (jb_client.result.dig(:total) || @contact_job.total_amount).to_d,
            ext_tech_id:                       (jb_client.result.dig(:visitSchedule, :assignedTo, :nodes)&.first&.dig(:id) || @contact_job.ext_tech_id).to_s,
            invoice_number:                    (jb_client.result.dig(:invoices, :nodes)&.first&.dig(:invoiceNumber) || @contact_job.invoice_number).to_s
          )

          create_or_update_lineitems(@contact_job, jb_client.result.dig(:lineItems, :nodes))
          destroy_deleted_lineitems(@contact_job, jb_client.result.dig(:lineItems, :nodes))

          if jb_client.result.dig(:quote, :id).present? && (contact_estimate = @contact.estimates.find_by(ext_source: 'jobber', ext_id: jb_client.result.dig(:quote, :id).to_s))
            contact_estimate.update(job_id: @contact_job.id)
          end

          true
        end

        def create_or_update_lineitems(job_or_estimate, jobber_lineitems)
          jobber_lineitems&.each do |line_item|
            job_or_estimate.lineitems.find_or_create_by(ext_id: line_item.dig(:linkedProductOrService, :id) || '', name: line_item.dig(:description).to_s, total: line_item.dig(:totalPrice).to_d)
          end
        end

        # create or update a Contacts::Request from a Jobber request
        # create_or_update_request(jobber_request_id)
        #   (req) jobber_request_id: (String)
        def create_or_update_request(jobber_request_id)
          JsonLog.info 'Integration::Jobber::V20220915::Event.create_or_update_request', { jobber_request_id:, event_action: @event_action }, client_id: @client_api_integration&.client_id, contact_id: @contact&.id
          return false unless self.ok_to_process && jobber_request_id.present? &&
                              Integration::Jobber::V20220915::Base.new(@client_api_integration).valid_credentials? && (jb_client = Integrations::JobBer::V20220915::Base.new(@client_api_integration.credentials))

          if @event_action == 'destroy'

            if (contact_request = Contacts::Request.joins(:contact).where(contact: { client_id: @client_api_integration.client_id }).find_by(ext_source: 'jobber', ext_id: jobber_request_id))
              contact_request.update(status: 'destroyed')
              @contact = contact_request.contact
            end

            return true
          end

          return false unless jb_client.request(jobber_request_id).present? && jb_client.success? && create_or_update_contact(jb_client.result.dig(:client, :id)) &&
                              (@contact_request = @contact.requests.find_or_initialize_by(ext_source: 'jobber', ext_id: jobber_request_id)).present?

          create_or_update_job(jb_client.result.dig(:job, :id)) if jb_client.result.dig(:job, :id).present?

          @start_date_updated = Chronic.parse(jb_client.result.dig(:createdAt)) != @contact_request.start_at

          @client_api_integration.update(request_sources: (@client_api_integration.request_sources || []) << jb_client.result.dig(:source).to_s.downcase.strip) if jb_client.result.dig(:source).to_s.strip.present? && (@client_api_integration.request_sources || []).exclude?(jb_client.result.dig(:source).to_s.downcase.strip)

          @contact_request.update(
            status:   jb_client.result.dig(:requestStatus).to_s.downcase,
            start_at: Chronic.parse(jb_client.result.dig(:createdAt)) || @contact_request.start_at,
            source:   jb_client.result.dig(:source).to_s.downcase
          )

          true
        end

        # create or update a Contacts::Visit from a Jobber visit
        # create_or_update_visit(jobber_visit_id)
        #   (req) jobber_visit_id: (String)
        def create_or_update_visit(jobber_visit_id)
          JsonLog.info 'Integration::Jobber::V20220915::Event.create_or_update_visit', { jobber_visit_id:, event_action: @event_action }, client_id: @client_api_integration&.client_id, contact_id: @contact&.id
          return false unless self.ok_to_process && jobber_visit_id.present? &&
                              Integration::Jobber::V20220915::Base.new(@client_api_integration).valid_credentials? && (jb_client = Integrations::JobBer::V20220915::Base.new(@client_api_integration.credentials))

          if @event_action == 'destroy'

            if (contact_visit = Contacts::Visit.joins(:contact).where(contact: { client_id: @client_api_integration.client_id }).find_by(ext_source: 'jobber', ext_id: jobber_visit_id))
              contact_visit.update(status: 'destroyed')
              @contact = contact_visit.contact
            end

            return true
          end

          return false unless jb_client.visit(jobber_visit_id).present? && jb_client.success? && create_or_update_contact(jb_client.result.dig(:client, :id)) &&
                              create_or_update_job(jb_client.result.dig(:job, :id)) && (@contact_visit = @contact.visits.find_or_initialize_by(ext_source: 'jobber', ext_id: jobber_visit_id)).present?

          @start_date_updated = Chronic.parse(jb_client.result.dig(:startAt)) != @contact_visit.start_at
          @tech_updated       = jb_client.result.dig(:assignedUsers, :nodes)&.first&.dig(:id) != @contact_visit.ext_tech_id

          @contact_visit.update(
            job_id:        @contact_job.id,
            status:        jb_client.result.dig(:visitStatus).to_s.downcase,
            start_at:      Chronic.parse(jb_client.result.dig(:startAt)) || @contact_visit.start_at,
            end_at:        Chronic.parse(jb_client.result.dig(:endAt)) || @contact_visit.end_at,
            ext_tech_id:   (jb_client.result.dig(:assignedUsers, :nodes)&.first&.dig(:id) || @contact_visit.ext_tech_id).to_s,
            customer_type: (if jb_client.result.dig(:client, :isCompany).nil?
                              nil
                            else
                              (jb_client.result[:client][:isCompany].to_bool ? 'Commercial' : 'Residential')
                            end) || @contact_job.customer_type
          )

          true
        end

        def destroy_deleted_lineitems(job_or_estimate, jobber_lineitems)
          (job_or_estimate.lineitems.pluck(:ext_id, :name) - jobber_lineitems.filter_map { |lineitem| [lineitem.dig(:linkedProductOrService, :id) || '', lineitem.dig(:description).to_s] }).each do |li|
            job_or_estimate.lineitems.find_by(ext_id: li.first, name: li.second)&.destroy
          end
        end

        # qualify event with criteria & process actions is match
        # process_actions_for_event
        def process_actions_for_event
          JsonLog.info 'Integration::Jobber::V20220915::Event.process_actions_for_event', { event_action: @event_action, event_new: @event_new, event_object: @event_object, start_date_updated: @start_date_updated, tech_updated: @tech_updated, contact_job: @contact_job, contact_estimate: @contact_estimate, contact_visit: @contact_visit }, client_id: @client_api_integration&.client_id, contact_id: @contact&.id
          return unless self.ok_to_process

          @client_api_integration.webhooks.dig("#{@event_object}_#{@event_action}")&.each do |event|
            event.deep_symbolize_keys!

            next if not_event_new?(event)
            next unless customer_type_matches?(event)
            next if not_event_line_items_match?(event)
            next if not_event_ext_tech_id_match?(event)
            next if not_event_tags_include?(event)
            next if not_event_tags_exclude?(event)
            next if not_event_status_match?(event)
            next if not_event_start_date_updated?(event)
            next if not_event_tech_updated?(event)
            next if not_event_source_match?(event)

            @contact.assign_user(@client_api_integration.employees.dig(@contact_job&.ext_tech_id)) if event.dig(:actions, :assign_user) && @contact_job&.ext_tech_id.present? && @client_api_integration.employees.dig(@contact_job&.ext_tech_id).present?
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
          if %w[job].include?(@event_object)
            event.dig(:criteria, :customer_type).blank? || @contact_job&.customer_type.nil? || event.dig(:criteria, :customer_type).include?(@contact_job&.customer_type)
          elsif %w[invoice].include?(@event_object)
            event.dig(:criteria, :customer_type).blank? || @contact_invoice&.customer_type.nil? || event.dig(:criteria, :customer_type).include?(@contact_invoice&.customer_type)
          elsif %w[quote].include?(@event_object)
            event.dig(:criteria, :customer_type).blank? || @contact_estimate&.customer_type.nil? || event.dig(:criteria, :customer_type).include?(@contact_estimate&.customer_type)
          elsif %w[request].include?(@event_object)
            event.dig(:criteria, :customer_type).blank? || @contact_request&.customer_type.nil? || event.dig(:criteria, :customer_type).include?(@contact_request&.customer_type)
          elsif %w[visit].include?(@event_object)
            event.dig(:criteria, :customer_type).blank? || @contact_visit&.customer_type.nil? || event.dig(:criteria, :customer_type).include?(@contact_visit&.customer_type)
          else
            true
          end
        end

        def not_event_ext_tech_id_match?(event)
          if %w[job].include?(@event_object)
            event.dig(:criteria, :ext_tech_ids).present? && @contact_job&.ext_tech_id.present? && event.dig(:criteria, :ext_tech_ids).exclude?(@contact_job&.ext_tech_id)
          elsif %w[visit].include?(@event_object)
            event.dig(:criteria, :ext_tech_ids).present? && @contact_visit&.ext_tech_id.present? && event.dig(:criteria, :ext_tech_ids).exclude?(@contact_visit&.ext_tech_id)
          else
            false
          end
        end

        def not_event_line_items_match?(event)
          if %w[quote].include?(@event_object)
            event.dig(:criteria, :line_items).present? && !event.dig(:criteria, :line_items).intersect?(@contact_estimate&.lineitems&.pluck(:ext_id))
          elsif %w[job visit].include?(@event_object)
            event.dig(:criteria, :line_items).present? && !event.dig(:criteria, :line_items).intersect?(@contact_job&.lineitems&.pluck(:ext_id))
          elsif %w[invoice].include?(@event_object)
            event.dig(:criteria, :line_items).present? && !event.dig(:criteria, :line_items).intersect?(@contact_invoice&.lineitems&.pluck(:ext_id))
          else
            false
          end
        end

        def not_event_new?(event)
          @event_action == 'update' && (event.dig(:criteria, :event_new) != @event_new) && (event.dig(:criteria, :event_updated) != !@event_new)
        end

        def not_event_source_match?(event)
          if %w[request].include?(@event_object)
            event.dig(:criteria, :source).present? && event.dig(:criteria, :source).exclude?(@contact_request&.source)
          else
            false
          end
        end

        def not_event_start_date_updated?(event)
          %w[job visit].include?(@event_object) && event.dig(:criteria, :start_date_updated) && !@start_date_updated
        end

        def not_event_status_match?(event)
          if %w[invoice].include?(@event_object)
            event.dig(:criteria, :status).present? && event.dig(:criteria, :status).exclude?(@contact_invoice&.status)
          elsif %w[job].include?(@event_object)
            event.dig(:criteria, :status).present? && event.dig(:criteria, :status).exclude?(@contact_job&.status)
          elsif %w[quote].include?(@event_object)
            event.dig(:criteria, :status).present? && event.dig(:criteria, :status).exclude?(@contact_estimate&.status)
          elsif %w[request].include?(@event_object)
            event.dig(:criteria, :status).present? && event.dig(:criteria, :status).exclude?(@contact_request&.status)
          elsif %w[visit].include?(@event_object)
            event.dig(:criteria, :status).present? && event.dig(:criteria, :status).exclude?(@contact_visit&.status)
          else
            false
          end
        end

        def not_event_tags_exclude?(event)
          event.dig(:criteria, :tag_ids_exclude).present? && event.dig(:criteria, :tag_ids_exclude).intersect?(@contact.tags.pluck(:id))
        end

        def not_event_tags_include?(event)
          event.dig(:criteria, :tag_ids_include).present? && !event.dig(:criteria, :tag_ids_include).intersect?(@contact.tags.pluck(:id))
        end

        def not_event_tech_updated?(event)
          %w[job visit].include?(@event_object) && event.dig(:criteria, :tech_updated) && !@tech_updated
        end
      end
    end
  end
end

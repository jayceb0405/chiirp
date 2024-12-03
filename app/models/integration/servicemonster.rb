# frozen_string_literal: true

# app/models/integration/servicemonster.rb
module Integration
  class Servicemonster < ApplicationRecord
    # client_id = xx
    # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'servicemonster', name: ''); Integration::Servicemonster.valid_credentials?(client_api_integration); sm_client = Integrations::ServiceMonster.new(client_api_integration.credentials)

    # return a string that may be used to inform the User how many more ServiceMonster accounts are remaining in the queue to be imported
    # Integration::Servicemonster.contact_imports_remaining_string(Integer)
    def self.contact_imports_remaining_string(client_id)
      return unless (client_api_integration = ClientApiIntegration.find_by(client_id:, target: 'servicemonster', name: '')) && self.valid_credentials?(client_api_integration)

      sm_client               = Integrations::ServiceMonster.new(client_api_integration.credentials)
      imports                 = DelayedJob.where(process: 'servicemonster_import_accounts').where('data @> ?', { client_id: }.to_json).count
      grouped_contact_imports = DelayedJob.where(process: 'servicemonster_import_accounts_group').where('data @> ?', { client_id: }.to_json).count * sm_client.default_page_size
      contact_imports         = [0, DelayedJob.where(process: 'servicemonster_update_contact_from_account').where('data @> ?', { client_id: }.to_json).count - 1].max

      if imports.positive? && (grouped_contact_imports + contact_imports).zero?
        'Queued'
      else
        "#{grouped_contact_imports.positive? ? '< ' : ''}#{grouped_contact_imports + contact_imports}"
      end
    end

    # lookup ServiceMonster Lead Source and return Chiirp Lead Source
    # Integration::Servicemonster.convert_sm_lead_source_id(sm_lead_source_id)
    def self.convert_sm_lead_source_id(client_api_integration, sm_lead_source_id)
      JsonLog.info 'Integration::Servicemonster.convert_sm_lead_source_id', { sm_lead_source_id:, client_api_integration: client_api_integration.attributes_cleaned }
      return nil unless sm_lead_source_id.present? && client_api_integration.is_a?(ClientApiIntegration) && self.valid_credentials?(client_api_integration)

      sm_client       = Integrations::ServiceMonster.new(client_api_integration.credentials)
      sm_lead_sources = sm_client.lead_sources
      lead_source     = nil

      if (sm_lead_source = sm_lead_sources.find { |ls| ls[:leadSourceID] == sm_lead_source_id }) && !(lead_source = client_api_integration.client.lead_sources.find_by(name: sm_lead_source.dig(:name)))
        lead_source = client_api_integration.client.lead_sources.create(name: sm_lead_source.dig(:name))
      end

      lead_source
    end

    def self.credentials_exist?(client_api_integration)
      client_api_integration&.company&.dig('companyKey').present?
    end

    # deprovision all unuser ServiceMonster webhooks
    # Integration::Servicemonster.deprovision_unused_webhooks_for_all_clients
    def self.deprovision_unused_webhooks_for_all_clients
      JsonLog.info 'Integration::Servicemonster.deprovision_unused_webhooks_for_all_clients'
      ClientApiIntegration.where(target: 'servicemonster', name: '').find_each do |client_api_integration|
        next unless Integration::Servicemonster.valid_credentials?(client_api_integration)

        sm_client = Integrations::ServiceMonster.new(client_api_integration.credentials)
        old_webhook_ids = sm_client.webhooks.map { |webhook| webhook.dig(:targetURL).split('/').last if webhook.dig(:active) }.compact_blank - client_api_integration.webhooks.map { |_event, webhook| webhook.dig('id') }

        old_webhook_ids.each do |old_webhook_id|
          sm_client.deprovision_webhook(old_webhook_id)
        end
      end
    end

    # process event reveived by webhook or retrieved by API call
    # Integration::Servicemonster.event_process()
    # (req) client_api_integration_ids: (Array) ClientApiIntegration ids
    # (req) params:                     (Hash)
    # (req)
    #   webhook_id:                     (String)
    #     ~ or ~
    #   event_object:                   (String)
    #   event_type:                     (String)
    # (opt) process_events:             (Boolean)
    # (opt) raw_params:                 (Hash)
    def self.event_process(args = {})
      JsonLog.info 'Integration::Servicemonster.event_process', { args: }
      return {} unless args.dig(:client_api_integration_ids).is_a?(Array) && args[:client_api_integration_ids].present?
      return {} if args.dig(:event_object).blank? && args.dig(:event_type).blank? && args.dig(:webhook_id).blank?

      parsed_webhook = {}

      ClientApiIntegration.where(id: args[:client_api_integration_ids], target: 'servicemonster', name: '').includes(:client).find_each do |client_api_integration|
        next unless client_api_integration.client.active? && self.valid_credentials?(client_api_integration)
        next if args.dig(:event_object).blank? && args.dig(:event_type).blank? && (webhook = self.webhook_by_id(client_api_integration.webhooks, args.dig(:webhook_id))).blank?

        event_object   = (args.dig(:event_object) || webhook.keys.first.to_s.split('_').first).to_s # account, order, appointment
        event_type     = (args.dig(:event_type) || webhook.keys.first.to_s.split('_').last).to_s # OnCreated, OnUpdated, OnArchived, OnDeleted, OnInvoiced
        parsed_webhook = Integrations::ServiceMonster.new(client_api_integration.credentials).parse_webhook(
          company_id:   client_api_integration.company&.dig('companyID'),
          event_object:,
          event_type:,
          params:       args.dig(:params)
        )

        next unless parsed_webhook[:success] && (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client_api_integration.client_id, phones: parsed_webhook.dig(:contact, :phones), emails: parsed_webhook.dig(:contact, :email), ext_refs: { 'servicemonster' => parsed_webhook.dig(:contact, :id) }))

        contact.lastname       = (parsed_webhook.dig(:contact, :lastname) || contact.lastname).to_s
        contact.firstname      = (parsed_webhook.dig(:contact, :firstname) || contact.firstname).to_s
        contact.companyname    = (parsed_webhook.dig(:contact, :companyname) || contact.companyname).to_s
        contact.address1       = (parsed_webhook.dig(:contact, :address_01) || contact.address1).to_s
        contact.address2       = (parsed_webhook.dig(:contact, :address_02) || contact.address2).to_s
        contact.city           = (parsed_webhook.dig(:contact, :city) || contact.city).to_s
        contact.state          = (parsed_webhook.dig(:contact, :state) || contact.state).to_s
        contact.zipcode        = (parsed_webhook.dig(:contact, :postal_code) || contact.zipcode).to_s
        contact.lead_source_id = self.convert_sm_lead_source_id(client_api_integration, (parsed_webhook.dig(:order, :lead_source_id).presence || parsed_webhook.dig(:contact, :lead_source_id).presence))&.id

        next unless contact.save

        previous_events = case event_object
                          when 'account'
                            contact.raw_posts.where(ext_source: 'servicemonster', ext_id: "#{event_object}_#{event_type}").where('data @> ?', { accountID: parsed_webhook.dig(:contact, :id) }.to_json)
                          when 'order'
                            contact.raw_posts.where(ext_source: 'servicemonster', ext_id: "#{event_object}_#{event_type}").where('data @> ?', { orderID: parsed_webhook.dig(:order, :id) }.to_json)
                          when 'appointment'
                            contact.raw_posts.where(ext_source: 'servicemonster', ext_id: "#{event_object}_#{event_type}").where('data @> ?', { jobID: parsed_webhook.dig(:appointment, :id) }.to_json).where('data @> ?', { jobStatus: parsed_webhook.dig(:appointment, :status).capitalize }.to_json)
                          else
                            []
                          end
        previous_appointment = event_object == 'appointment' ? contact.raw_posts.where(ext_source: 'servicemonster').where('ext_id ILIKE ?', "#{event_object}_%").where('data @> ?', { jobID: parsed_webhook.dig(:appointment, :id) }.to_json).order(created_at: :desc).first : nil

        process_actions_data = {
          account_type:           parsed_webhook.dig(:contact, :account_type).to_s,
          account_subtype:        parsed_webhook.dig(:contact, :account_subtype).to_s,
          client_api_integration:,
          commercial:             parsed_webhook.dig(:contact, :commercial).to_bool,
          contact:,
          contact_order:          nil,
          event_object:,
          event_new:              previous_events.none?,
          event_type:,
          order:                  parsed_webhook.dig(:order),
          order_group:            parsed_webhook.dig(:order, :group),
          order_subgroup:         parsed_webhook.dig(:order, :subgroup),
          order_type:             parsed_webhook.dig(:order, :type).to_s.sub('work ', ''),
          order_type_voided:      parsed_webhook.dig(:order, :type_voided).to_bool,
          residential:            !parsed_webhook.dig(:contact, :commercial).to_bool,
          start_date_updated:     event_object == 'appointment' && !previous_appointment&.data&.dig('estDateTimeStart').to_s.casecmp?(parsed_webhook.dig(:appointment, :scheduled, :start_at).to_s),
          status_updated:         event_object == 'appointment' && !previous_appointment&.data&.dig('jobStatus').to_s.casecmp?(parsed_webhook.dig(:appointment, :status).to_s),
          tech_updated:           event_object == 'appointment' && previous_appointment&.data&.dig('assignedEmployeeIDs').to_a.exclude?(parsed_webhook.dig(:appointment, :ext_tech_id).to_s),
          webhook:
        }

        # save params to Contact::RawPosts
        contact.raw_posts.create(ext_source: 'servicemonster', ext_id: "#{event_object}_#{event_type}", data: args[:raw_params]) if args.dig(:raw_params).present?

        self.update_account_types(client_api_integration:, account_type: parsed_webhook.dig(:contact, :account_type).to_s)
        self.update_account_subtypes(client_api_integration:, account_subtype: parsed_webhook.dig(:contact, :account_subtype).to_s)
        self.update_order_groups(client_api_integration:, order_group: parsed_webhook.dig(:order, :group).to_s)
        self.update_order_subgroups(client_api_integration:, order_subgroup: parsed_webhook.dig(:order, :subgroup).to_s)

        # save/update Contact::Estimate
        case event_object
        when 'order'

          case parsed_webhook.dig(:order, :type).to_s
          when 'estimate'
            process_actions_data[:contact_estimate_id] = self.update_estimate(contact, parsed_webhook)&.id
            parsed_webhook[:contact_estimate_id]       = process_actions_data[:contact_estimate_id]
          when 'work order', 'invoice'
            process_actions_data[:contact_job_id] = self.update_job(contact, parsed_webhook)&.id
            parsed_webhook[:contact_job_id]       = process_actions_data[:contact_job_id]
          end

        when 'appointment'
          process_actions_data[:contact_estimate_id], process_actions_data[:contact_job_id], process_actions_data[:appointment_status] = self.update_schedule(contact, parsed_webhook)
          process_actions_data[:ext_tech_id]      = parsed_webhook.dig(:appointment, :ext_tech_id)
          process_actions_data[:ext_sales_rep_id] = parsed_webhook.dig(:appointment, :ext_sales_rep_id)
          process_actions_data[:job_type]         = parsed_webhook.dig(:appointment, :job_type)
          parsed_webhook[:contact_estimate_id]    = process_actions_data[:contact_estimate_id]
          parsed_webhook[:contact_job_id]         = process_actions_data[:contact_job_id]

          self.update_job_types(client_api_integration:, job_type: parsed_webhook.dig(:order, :job_type).to_s)
        end

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
      end

      parsed_webhook
    end

    # import ServiceMonster accounts
    # Integration::Servicemonster.import_accounts(client_api_integration: ClientApiIntegration, user_id: Integer, new_contacts_only: Boolean)
    #   (req) client_api_integration: (ClientApiIntegration)
    #   (opt) new_contacts_only:      (Boolean)
    #   (req) user_id:                (Integer)
    def self.import_accounts(args)
      JsonLog.info 'Integration::Servicemonster.import_accounts', { args: }
      return false unless args.dig(:user_id).to_i.positive? && args.dig(:client_api_integration).is_a?(ClientApiIntegration) && self.valid_credentials?(args[:client_api_integration])

      new_contacts_only = args.dig(:new_contacts_only).nil? ? true : args[:new_contacts_only].to_bool
      sm_client         = Integrations::ServiceMonster.new(args[:client_api_integration].credentials)
      page_count        = sm_client.accounts_count.to_i.divmod(sm_client.default_page_size)
      page_count        = page_count[0] + (page_count[1].positive? ? 1 : 0)

      (0..page_count).each do |page_index|
        self.delay(
          run_at:              Time.current,
          priority:            DelayedJob.job_priority('servicemonster_import_accounts_group'),
          queue:               DelayedJob.job_queue('servicemonster_import_accounts_group'),
          contact_id:          0,
          contact_campaign_id: 0,
          user_id:             args[:user_id].to_i,
          triggeraction_id:    0,
          process:             'servicemonster_import_accounts_group',
          group_process:       0,
          data:                { client_api_integration: args[:client_api_integration], user_id: args[:user_id].to_i, new_contacts_only:, page_index: }
        ).import_accounts_group(client_api_integration: args[:client_api_integration], user_id: args[:user_id].to_i, new_contacts_only:, page_index:)
        JsonLog.info 'Integration::Servicemonster.import_accounts_group', { page_index: }
      end

      CableBroadcaster.new.contacts_import_remaining(client: args[:client_api_integration].client_id, count: self.contact_imports_remaining_string(args[:client_api_integration].client_id))

      true
    end

    # import a page of ServiceMonster accounts
    # Integration::Servicemonster.import_account_group(client_api_integration: ClientApiIntegration, user_id: Integer, new_contacts_only: Boolean, page_index: Integer)
    def self.import_accounts_group(args)
      JsonLog.info 'Integration::Servicemonster.import_accounts_group', { args: }
      return false unless args.dig(:user_id).to_i.positive? && args.dig(:client_api_integration).is_a?(ClientApiIntegration) && self.valid_credentials?(args[:client_api_integration])

      new_contacts_only = args.dig(:new_contacts_only).nil? ? true : args.dig(:new_contacts_only).to_bool
      sm_client         = Integrations::ServiceMonster.new(args[:client_api_integration].credentials)

      sm_client.accounts(page_index: args.dig(:page_index).to_i, page_size: sm_client.default_page_size).each do |account|
        self.delay(
          run_at:              Time.current,
          priority:            DelayedJob.job_priority('servicemonster_update_contact_from_account'),
          queue:               DelayedJob.job_queue('servicemonster_update_contact_from_account'),
          contact_id:          0,
          contact_campaign_id: 0,
          user_id:             args[:user_id].to_i,
          triggeraction_id:    0,
          process:             'servicemonster_update_contact_from_account',
          group_process:       0,
          data:                { account:, client_api_integration: args[:client_api_integration], client_id: args[:client_api_integration].client_id, new_contacts_only: }
        ).update_contact_from_account(account:, client_api_integration: args[:client_api_integration], client_id: args[:client_api_integration].client_id, new_contacts_only:)
        JsonLog.info 'Integration::Servicemonster.update_contact_from_account', { page_index: args.dig(:page_index).to_i, account: account.dig(:row_number) }
      end

      CableBroadcaster.new.contacts_import_remaining(client: args[:client_api_integration].client_id, count: self.contact_imports_remaining_string(args[:client_api_integration].client_id))

      true
    end

    # import a ServiceMonster job
    # Integration::Servicemonster.import_job(client_api_integration_id: Integer, job: Hash, process_events: Boolean, user_id: Integer)
    def self.import_job(args)
      JsonLog.info 'Integration::Servicemonster.import_job', { args: }
      return unless args.dig(:job_id).present? && args.dig(:client_api_integration_id).to_i.positive? && (client_api_integration = ClientApiIntegration.find_by(id: args[:client_api_integration_id].to_i, target: 'servicemonster', name: '')) && self.valid_credentials?(client_api_integration)

      self.update_job_imports_remaining_count(Client.find_by(id: args.dig(:client_id)), User.find_by(client_id: args.dig(:client_id), id: args.dig(:user_id)))

      sm_client = Integrations::ServiceMonster.new(client_api_integration.credentials)

      return unless (job = sm_client.job(args[:job_id]))

      result = self.event_process({
                                    client_api_integration_ids: [client_api_integration.id],
                                    event_object:               'appointment',
                                    event_type:                 'OnCreated',
                                    params:                     job,
                                    process_events:             false,
                                    raw_params:                 {},
                                    webhook_id:                 ''
                                  })

      return unless (contact = Contact.joins(:ext_references).find_by(client_id: client_api_integration.client_id, ext_references: { target: 'servicemonster', ext_id: result.dig(:contact, :id) }))
      return unless self.order_type_matches?(
        order:    {
          type:   result.dig(:order, :type).to_s.sub('work ', ''),
          voided: result.dig(:order, :type_voided)
        },
        criteria: {
          type:   args.dig(:order_type),
          voided: args.dig(:order_type_voided)
        }
      )
      return unless args.dig(:ext_tech_ids).blank? || args.dig(:ext_tech_ids).intersect?([result.dig(:appointment, :ext_tech_id)])
      return unless args.dig(:account_types).blank? || args.dig(:account_types).include?(result.dig(:contact, :account_type).to_s.downcase)
      return unless args.dig(:account_sub_types).blank? || args.dig(:account_sub_types).include?(result.dig(:contact, :account_subtype).to_s.downcase)
      return unless args.dig(:order_groups).blank? || args.dig(:order_groups).include?(result.dig(:order, :group).to_s.downcase)
      return unless args.dig(:order_subgroups).blank? || args.dig(:order_subgroups).include?(result.dig(:order, :subgroup).to_s.downcase)
      return unless args.dig(:appointment_status).blank? || args.dig(:appointment_status).include?(result.dig(:appointment, :status).to_s.downcase)
      return unless args.dig(:job_types).blank? || args.dig(:job_types).include?(result.dig(:appointment, :job_type).to_s.downcase)
      return unless (args.dig(:commercial).to_bool && result.dig(:contact, :commercial).to_bool) || (args.dig(:residential).to_bool && !result.dig(:contact, :commercial).to_bool)
      return unless self.line_items_include?(
        order_type:          result.dig(:order, :type).to_s.sub('work ', ''),
        event_object:        'appointment',
        line_items:          Contacts::Job.find_by(id: result.dig(:contact_job_id))&.lineitems&.pluck(:ext_id).presence || Contacts::Estimate.find_by(id: result.dig(:contact_estimate_id))&.lineitems&.pluck(:ext_id).presence || [],
        line_items_criteria: args.dig(:line_items)
      )
      return unless self.qualifying_total?(
        order_type:   result.dig(:order, :type).to_s.sub('work ', ''),
        event_object: 'appointment',
        total_amount: Contacts::Job.find_by(id: result.dig(:contact_job_id))&.total_amount.presence || Contacts::Estimate.find_by(id: result.dig(:contact_estimate_id))&.total_amount.presence || 0,
        total_min:    args.dig(:total_min),
        total_max:    args.dig(:total_max)
      )

      contact.process_actions(
        campaign_id:         args.dig(:actions, :campaign_id),
        group_id:            args.dig(:actions, :group_id),
        stage_id:            args.dig(:actions, :stage_id),
        tag_id:              args.dig(:actions, :tag_id),
        stop_campaign_ids:   args.dig(:actions, :stop_campaign_ids),
        contact_job_id:      result.dig(:contact_job_id),
        contact_estimate_id: result.dig(:contact_estimate_id)
      )
    end

    # import ServiceMonster jobs (appointments)
    # Integration::Servicemonster.import_jobs(client_api_integration_id: Integer)
    # Integration::Servicemonster.import_jobs(client_api_integration_id: Integer, page: Integer, page_size: Integer)
    def self.import_jobs(args)
      JsonLog.info 'Integration::Servicemonster.import_jobs', { args: }
      return unless args.dig(:client_api_integration_id).to_i.positive? && (client_api_integration = ClientApiIntegration.find_by(id: args[:client_api_integration_id].to_i, target: 'servicemonster', name: '')) && self.valid_credentials?(client_api_integration)

      sm_client = Integrations::ServiceMonster.new(client_api_integration.credentials)
      page      = (args.dig(:page) || -1).to_i
      page_size = (args.dig(:page_size) || sm_client.default_page_size).to_i
      date_type = args.dig(:scheduled_start_min).present? ? 'start' : 'end'
      date_min  = args.dig(:scheduled_start_min).presence || args.dig(:scheduled_end_min).presence
      date_max  = args.dig(:scheduled_start_max).presence || args.dig(:scheduled_end_max).presence || date_min

      if page.negative?
        # break up SM Jobs into blocks
        sm_client.jobs_count(date_min:, date_type:)

        if sm_client.success?
          page_count = sm_client.result.to_i.divmod(page_size)
          page_count = page_count[0] + (page_count[1].positive? ? 1 : 0) - 1

          # generate DelayedJobs to import all ServiceMonster jobs (appointments)
          (0..page_count).each do |pp|
            data = args.merge({
                                page:      pp,
                                page_size:
                              })
            self.delay(
              run_at:              Time.current,
              priority:            DelayedJob.job_priority('servicemonster_import_jobs_block'),
              queue:               DelayedJob.job_queue('servicemonster_import_jobs_block'),
              user_id:             args.dig(:user_id),
              contact_id:          0,
              triggeraction_id:    0,
              contact_campaign_id: 0,
              group_process:       1,
              process:             'servicemonster_import_jobs_block',
              data:
            ).import_jobs(data)
          end
        end
      else
        # get the ServiceMonster job data for a specific page
        sm_client.jobs(date_min:, date_type:, page:, page_size:)

        if sm_client.success?
          date_max   = date_max.respond_to?(:iso8601) ? date_max.utc : nil
          date_field = :"estDateTime#{date_type.titleize}"

          # import Jobs for Contact
          sm_client.result.each_with_index do |job, index|
            if date_max.nil? || Chronic.parse(job.dig(date_field)).utc <= date_max
              data = args.merge({
                                  job_id: job.dig(:jobID)
                                })
              self.delay(
                run_at:              (index * 10).seconds.from_now,
                priority:            DelayedJob.job_priority('servicemonster_import_job'),
                queue:               DelayedJob.job_queue('servicemonster_import_job'),
                user_id:             args.dig(:user_id),
                contact_id:          0,
                triggeraction_id:    0,
                contact_campaign_id: 0,
                group_process:       0,
                process:             'servicemonster_import_job',
                data:
              ).import_job(data)
            end
          end
        end
      end
    end

    # return a string that may be used to inform the User how many more Servicemonster jobs are remaining in the queue to be imported
    # Integration::Servicemonster.job_imports_remaining_string(Integer)
    def self.job_imports_remaining_string(client_id)
      return unless (client_api_integration = ClientApiIntegration.find_by(client_id:, target: 'servicemonster', name: '')) && self.valid_credentials?(client_api_integration)

      sm_client           = Integrations::ServiceMonster.new(client_api_integration.credentials)
      imports             = DelayedJob.where(process: 'servicemonster_import_jobs').where('data @> ?', { client_id: }.to_json).count
      grouped_job_imports = DelayedJob.where(process: 'servicemonster_import_jobs_block').where('data @> ?', { client_id: }.to_json).count * sm_client.default_page_size
      job_imports         = [0, DelayedJob.where(process: 'servicemonster_import_job').where('data @> ?', { client_id: }.to_json).count - 1].max

      if imports.positive?
        'ServiceMonster job imports are queued.'
      elsif (grouped_job_imports + job_imports).positive?
        ActionController::Base.helpers.safe_join(['ServiceMonster jobs awaiting import: ', ActionController::Base.helpers.content_tag(:span, grouped_job_imports + job_imports, class: 'badge badge-lg badge-success')])
      else
        ''
      end
    end

    def self.line_items_include?(args)
      return true if args.dig(:line_items_criteria).blank?
      return true if args.dig(:line_items).present? && %w[estimate invoice order].include?(args.dig(:order_type).to_s) && args.dig(:line_items).intersect?(args.dig(:line_items_criteria))
      return true if args.dig(:line_items).present? && args.dig(:event_object).to_s == 'appointment' && args.dig(:line_items).intersect?(args.dig(:line_items_criteria))
      return true if args.dig(:line_items).present? && args.dig(:event_object).to_s == 'appointment' && args.dig(:line_items).intersect?(args.dig(:line_items_criteria))

      false
    end

    def self.order_type_matches?(order:, criteria:)
      return true if criteria.dig(:type).blank?
      return true unless %w[estimate invoice order].include?(order.dig(:type).to_s.downcase)

      order.dig(:type).to_s.casecmp?(criteria.dig(:type).to_s) && (criteria.dig(:voided).nil? || order.dig(:voided).to_bool == criteria.dig(:voided).to_bool)
    end
    # order:    {
    #   type:   result.dig(:order, :type).to_s.sub('work ', ''),
    #   voided: result.dig(:order, :type_voided)
    # }
    # criteria: {
    #   type:   args.dig(:order_type),
    #   voided: args.dig(:order_type_voided)
    # }

    # process Campaign, Group, Tag, Stage for incoming ServiceMonster webhook
    # Integration::Servicemonster.process_actions_for_webhook()
    #   (req) client_api_integration: (ClientApiIntegration)
    #   (req) contact:                (Contact)
    #   (req) event_object:           (String)
    def self.process_actions_for_webhook(args)
      JsonLog.info 'Integration::Servicemonster.process_actions_for_webhook', { args: }
      return unless args.dig(:client_api_integration).is_a?(ClientApiIntegration) && args.dig(:contact).is_a?(Contact) && args.dig(:webhook).is_a?(Hash) && args.dig(:event_object).to_s.present?

      args.dig(:webhook).values.first.dig(:events)&.each do |webhook_event|
        next unless self.order_type_matches?(
          order:    {
            type:   args.dig(:order_type),
            voided: args.dig(:order_type_voided)
          },
          criteria: {
            type:   webhook_event.dig(:criteria, :order_type),
            voided: webhook_event.dig(:criteria, :order_type_voided)
          }
        )
        next unless webhook_event.dig(:criteria, :event_new).nil? || (webhook_event.dig(:criteria, :event_new).to_bool && args.dig(:event_new).to_bool) || (webhook_event.dig(:criteria, :event_updated).to_bool && !args.dig(:event_new).to_bool)
        next unless webhook_event.dig(:criteria, :appointment_status).blank? || webhook_event.dig(:criteria, :appointment_status).to_s == args.dig(:appointment_status).to_s
        next unless (webhook_event.dig(:criteria, :commercial).to_bool && args.dig(:commercial).to_bool) || (webhook_event.dig(:criteria, :residential).to_bool && args.dig(:residential).to_bool)
        next unless webhook_event.dig(:criteria, :account_types).blank? || webhook_event.dig(:criteria, :account_types).include?(args.dig(:account_type).to_s)
        next unless webhook_event.dig(:criteria, :account_subtypes).blank? || webhook_event.dig(:criteria, :account_subtypes).include?(args.dig(:account_subtype).to_s)
        next unless webhook_event.dig(:criteria, :job_types).blank? || webhook_event.dig(:criteria, :job_types).include?(args.dig(:job_type).to_s)
        next unless webhook_event.dig(:criteria, :order_groups).blank? || webhook_event.dig(:criteria, :order_groups).include?(args.dig(:order_group).to_s)
        next unless webhook_event.dig(:criteria, :order_subgroups).blank? || webhook_event.dig(:criteria, :order_subgroups).include?(args.dig(:order_subgroup).to_s)
        next unless webhook_event.dig(:criteria, :lead_sources).blank? || webhook_event.dig(:criteria, :lead_sources).include?(args[:contact].lead_source_id) || (webhook_event.dig(:criteria, :lead_sources).include?(0) && args[:contact].lead_source_id.nil?)

        # if appointment test for technician or start date updated or appointment scheduled requirements
        next if args[:event_object].to_s == 'appointment' && webhook_event.dig(:criteria, :tech_updated).to_bool && !args.dig(:tech_updated).to_bool
        next if args[:event_object].to_s == 'appointment' && webhook_event.dig(:criteria, :start_date_updated).to_bool && !args.dig(:start_date_updated).to_bool
        next if args[:event_object].to_s == 'appointment' && webhook_event.dig(:criteria, :status_updated).to_bool && !args.dig(:status_updated).to_bool
        next if args[:event_object].to_s == 'appointment' && webhook_event.dig(:criteria, :ext_tech_ids).present? && webhook_event.dig(:criteria, :ext_tech_ids).exclude?(args.dig(:ext_tech_id).to_s)

        # qualify line items
        next unless self.line_items_include?(
          order_type:          args.dig(:order_type),
          event_object:        args[:event_object],
          line_items:          Contacts::Job.find_by(id: args.dig(:contact_job_id).to_i)&.lineitems&.pluck(:ext_id).presence || Contacts::Estimate.find_by(id: args.dig(:contact_estimate_id).to_i)&.lineitems&.pluck(:ext_id).presence || [],
          line_items_criteria: webhook_event.dig(:criteria, :line_items)
        )

        # qualify total
        next unless self.qualifying_total?(
          order_type:   args.dig(:order_type),
          event_object: args[:event_object],
          total_amount: Contacts::Job.find_by(id: args.dig(:contact_job_id).to_i)&.total_amount.presence || Contacts::Estimate.find_by(id: args.dig(:contact_estimate_id).to_i)&.total_amount.presence || 0,
          total_min:    webhook_event.dig(:criteria, :total_min),
          total_max:    webhook_event.dig(:criteria, :total_max)
        )

        args[:contact].assign_user(args[:client_api_integration].employees.dig(args[:ext_tech_id].to_s)) if args.dig(:ext_tech_id).to_s.present? && webhook_event.dig(:actions, :assign_user_to_technician).to_bool && args[:client_api_integration].employees.dig(args[:ext_tech_id].to_s).to_i.positive?
        args[:contact].assign_user(args[:client_api_integration].employees.dig(args[:ext_sales_rep_id].to_s)) if args.dig(:ext_sales_rep_id).to_s.present? && webhook_event.dig(:actions, :assign_user_to_salesrep).to_bool && args[:client_api_integration].employees.dig(args[:ext_sales_rep_id].to_s).to_i.positive?

        args[:contact].process_actions(
          campaign_id:         webhook_event.dig(:actions, :campaign_id),
          group_id:            webhook_event.dig(:actions, :group_id),
          stage_id:            webhook_event.dig(:actions, :stage_id),
          tag_id:              webhook_event.dig(:actions, :tag_id),
          stop_campaign_ids:   webhook_event.dig(:actions, :stop_campaign_ids),
          contact_job_id:      args.dig(:contact_job_id),
          contact_estimate_id: args.dig(:contact_estimate_id)
        )
      end
    end

    def self.qualifying_total?(args)
      return true if args.dig(:total_max).to_i.zero?
      return true if %w[estimate invoice order].include?(args.dig(:order_type).to_s) && args.dig(:total_amount).to_i.between?(args.dig(:total_min).to_i, args.dig(:total_max).to_i)
      return true if args.dig(:event_object).to_s == 'appointment' && args.dig(:total_amount).to_i.between?(args.dig(:total_min).to_i, args.dig(:total_max).to_i)
      return true if args.dig(:event_object).to_s == 'appointment' && args.dig(:total_amount).to_i.between?(args.dig(:total_min).to_i, args.dig(:total_max).to_i)

      false
    end

    # remove reference to a Campaign/Group/Stage/Tag that was destroyed
    # Integration::Servicemonster.references_destroyed()
    #   (req) client_id:      (Integer)
    #   (opt) campaign_id:    (Integer)
    #   (opt) group_id:       (Integer)
    #   (opt) tag_id:         (Integer)
    #   (opt) stage_id:       (Integer)
    def self.references_destroyed(**args)
      return false unless (Integer(args.dig(:client_id), exception: false) || 0).positive? &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id], target: 'servicemonster', name: '')) &&
                          ((Integer(args.dig(:campaign_id), exception: false) || 0).positive? || (Integer(args.dig(:group_id), exception: false) || 0).positive? ||
                          (Integer(args.dig(:stage_id), exception: false) || 0).positive? || (Integer(args.dig(:tag_id), exception: false) || 0).positive?)

      campaign_id = args.dig(:campaign_id).to_i
      group_id    = args.dig(:group_id).to_i
      stage_id    = args.dig(:stage_id).to_i
      tag_id      = args.dig(:tag_id).to_i

      client_api_integration.webhooks&.each_value do |webhook|
        webhook.dig('events')&.each do |event|
          event['actions']['campaign_id'] = 0 if event.dig('actions', 'campaign_id').to_i == campaign_id
          event['actions']['group_id']    = 0 if event.dig('actions', 'group_id').to_i == group_id
          event['actions']['stage_id']    = 0 if event.dig('actions', 'stage_id').to_i == stage_id
          event['actions']['tag_id']      = 0 if event.dig('actions', 'tag_id').to_i == tag_id
        end
      end

      client_api_integration.save
    end

    # a Tag was applied to Contact / if Tag is defined to send Contact to ServiceMonster then send it
    # Integration::Servicemonster.tag_applied(contacttag: Contacttag)
    def self.tag_applied(args = {})
      JsonLog.info 'Integration::Servicemonster.tag_applied', { args: }
      return unless args.dig(:contacttag).is_a?(Contacttag) &&
                    (client_api_integration = ClientApiIntegration.find_by(client_id: args[:contacttag].contact.client_id, target: 'servicemonster', name: '')) && self.valid_credentials?(client_api_integration) &&
                    client_api_integration.push_leads_tag_id == args[:contacttag].tag_id

      contact_hash         = args[:contacttag].contact.attributes.deep_symbolize_keys
      contact_hash[:tags]  = args[:contacttag].contact.tags.map(&:name)
      contact_hash[:phone] = args[:contacttag].contact.primary_phone&.phone.to_s

      return if args[:contacttag].contact.ext_references.find_by(target: 'servicemonster').present?

      result = Integrations::ServiceMonster.new(client_api_integration.credentials).push_contact_to_servicemonster(contact: contact_hash)

      return if result&.dig(:recordID).to_s.blank?

      contact_ext_reference = args[:contacttag].contact.ext_references.find_or_initialize_by(target: 'servicemonster')
      contact_ext_reference.update(ext_id: result.dig(:recordID).to_s)
    end

    # Integration::Servicemonster.update_account_subtypes(client_api_integration: ClientApiIntegration, account_subtype: String)
    def self.update_account_subtypes(args = {})
      JsonLog.info 'Integration::Servicemonster.update_account_subtypes', { args: }
      return unless args.dig(:client_api_integration).is_a?(ClientApiIntegration) && args.dig(:account_subtype).present?
      return if (args[:client_api_integration].account_subtypes || []).include?(args[:account_subtype].to_s)

      args[:client_api_integration].update(account_subtypes: ((args[:client_api_integration].account_subtypes || []) << args[:account_subtype].to_s).uniq.sort)
    end

    # Integration::Servicemonster.update_account_types(client_api_integration: ClientApiIntegration, account_type: String)
    def self.update_account_types(args = {})
      JsonLog.info 'Integration::Servicemonster.update_account_types', { args: }
      return unless args.dig(:client_api_integration).is_a?(ClientApiIntegration) && args.dig(:account_type).to_s.present?
      return if (args[:client_api_integration].account_types || []).include?(args[:account_type].to_s)

      args[:client_api_integration].update(account_types: ((args[:client_api_integration].account_types || []) << args[:account_type].to_s).uniq.sort)
    end

    # add/update a Contact from a ServiceMonster account
    # Integration::Servicemonster.update_contact_from_account(client_api_integration: ClientApiIntegration, account: Hash, new_contacts_only: Boolean)
    def self.update_contact_from_account(args = {})
      JsonLog.info 'Integration::Servicemonster.update_contact_from_account', { args: }
      return false unless args.dig(:client_api_integration).is_a?(ClientApiIntegration) && args.dig(:account).is_a?(Hash) && self.valid_credentials?(args[:client_api_integration])

      new_contacts_only = args.dig(:new_contacts_only).nil? ? true : args.dig(:new_contacts_only).to_bool
      sm_client         = Integrations::ServiceMonster.new(args[:client_api_integration].credentials)
      full_account      = sm_client.account(args.dig(:account).dig(:accountID))
      JsonLog.info 'Integration::Servicemonster.update_contact_from_account-after', { account: args.dig(:account).dig(:accountID) }

      return false unless sm_client.success?

      phones = {}
      phones[full_account.dig(:phone1).to_s] = full_account.dig(:phone1Label).to_s if full_account.dig(:phone1).present?
      phones[full_account.dig(:phone2).to_s] = full_account.dig(:phone2Label).to_s if full_account.dig(:phone2).present?
      phones[full_account.dig(:phone3).to_s] = full_account.dig(:phone3Label).to_s if full_account.dig(:phone3).present?
      mobile_phone_index                     = [full_account.dig(:phone1Label).to_s, full_account.dig(:phone2Label).to_s, full_account.dig(:phone3Label).to_s].map(&:downcase).index('mobile')

      lead_source = self.convert_sm_lead_source_id(args[:client_api_integration], full_account.dig(:leadSourceID))

      if (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: args[:client_api_integration].client_id, phones:, emails: [full_account.dig(:email).to_s], ext_refs: { 'servicemonster' => full_account.dig(:accountID).to_s })) && (contact.new_record? || !new_contacts_only)
        contact.update(
          firstname:      full_account.dig(:firstName).to_s,
          lastname:       full_account.dig(:lastName).to_s,
          address1:       full_account.dig(:address1).to_s,
          address2:       full_account.dig(:address2).to_s,
          city:           full_account.dig(:city).to_s,
          state:          full_account.dig(:state).to_s,
          zipcode:        full_account.dig(:zip).to_s,
          ok2text:        (0 if mobile_phone_index && !full_account.dig(:"canText#{mobile_phone_index + 1}").to_bool),
          lead_source_id: lead_source&.id
        )
        JsonLog.info 'Integration::Servicemonster.update_contact_from_account', { account: args.dig(:account).dig(:accountID) }, contact_id: contact.id
      end

      self.update_account_subtypes(client_api_integration: args[:client_api_integration], account_subtype: full_account.dig(:accountSubType).to_s)
      self.update_account_types(client_api_integration: args[:client_api_integration], account_type: full_account.dig(:accountType).to_s)

      CableBroadcaster.new.contacts_import_remaining(client: args[:client_api_integration].client_id, count: self.contact_imports_remaining_string(args[:client_api_integration].client_id))

      true
    end

    def self.update_estimate(contact, parsed_webhook)
      JsonLog.info('Integration::Servicemonster.update_estimate', { parsed_webhook: }, contact_id: contact.id)
      return nil unless parsed_webhook.dig(:order, :id).present? && (contact_estimate = contact.estimates.find_or_initialize_by(ext_source: 'servicemonster', ext_id: parsed_webhook.dig(:order, :id).to_s))

      contact_estimate.update(
        estimate_number:     (parsed_webhook.dig(:order, :number) || contact_estimate.estimate_number).to_s,
        status:              (parsed_webhook.dig(:order, :status) || contact_estimate.status).to_s,
        address_01:          (parsed_webhook.dig(:site, :address_01) || contact_estimate.address_01).to_s,
        address_02:          (parsed_webhook.dig(:site, :address_02) || contact_estimate.address_02).to_s,
        city:                (parsed_webhook.dig(:site, :city) || contact_estimate.city).to_s,
        state:               (parsed_webhook.dig(:site, :state) || contact_estimate.state).to_s,
        postal_code:         (parsed_webhook.dig(:site, :postal_code) || contact_estimate.postal_code).to_s,
        country:             (parsed_webhook.dig(:site, :country) || contact_estimate.country).to_s,
        outstanding_balance: (parsed_webhook.dig(:order, :outstanding_balance) || contact_estimate.outstanding_balance).to_d,
        total_amount:        (parsed_webhook.dig(:order, :total_amount) || contact_estimate.total_amount).to_d
      )

      parsed_webhook.dig(:order, :line_items)&.each do |line_item|
        if (lineitem = contact_estimate.lineitems.find_or_create_by(ext_id: line_item.dig(:id).to_s))
          lineitem.update(name: line_item.dig(:name).to_s, total: line_item.dig(:total).to_d)
        end
      end

      if (deleted_lineitems = contact_estimate.lineitems.pluck(:ext_id) - parsed_webhook.dig(:order, :line_items).map { |line_item| line_item.dig(:id) }.compact_blank).present?
        contact_estimate.lineitems.where(ext_id: deleted_lineitems).destroy_all
      end

      contact_estimate
    end

    def self.update_job(contact, parsed_webhook)
      JsonLog.info 'Integration::Servicemonster.update_job', { parsed_webhook: }, contact_id: contact.id
      return nil unless parsed_webhook.dig(:order, :id).present? && (contact_job = contact.jobs.find_or_initialize_by(ext_source: 'servicemonster', ext_id: parsed_webhook.dig(:order, :id).to_s))

      contact_job.update(
        status:              (parsed_webhook.dig(:order, :status) || contact_job.status).to_s,
        job_type:            (parsed_webhook.dig(:order, :type) || contact_job.job_type).to_s,
        address_01:          (parsed_webhook.dig(:site, :address_01) || contact_job.address_01).to_s,
        address_02:          (parsed_webhook.dig(:site, :address_02) || contact_job.address_02).to_s,
        city:                (parsed_webhook.dig(:site, :city) || contact_job.city).to_s,
        state:               (parsed_webhook.dig(:site, :state) || contact_job.state).to_s,
        postal_code:         (parsed_webhook.dig(:site, :postal_code) || contact_job.postal_code).to_s,
        country:             (parsed_webhook.dig(:site, :country) || contact_job.country).to_s,
        total_amount:        (parsed_webhook.dig(:order, :total_amount) || contact_job.total_amount).to_d,
        outstanding_balance: (parsed_webhook.dig(:order, :outstanding_balance) || contact_job.outstanding_balance).to_d,
        invoice_number:      (parsed_webhook.dig(:order, :number) || contact_job.invoice_number).to_s
      )

      if (contact_estimate = contact.estimates.find_by(ext_source: 'servicemonster', ext_id: parsed_webhook.dig(:order, :id).to_s))
        contact_estimate.update(job_id: contact_job.id)
      end

      parsed_webhook.dig(:order, :line_items)&.each do |line_item|
        if (lineitem = contact_job.lineitems.find_or_create_by(ext_id: line_item.dig(:id).to_s))
          lineitem.update(name: line_item.dig(:name).to_s, total: line_item.dig(:total).to_d)
        end
      end

      if (deleted_lineitems = contact_job.lineitems.pluck(:ext_id) - parsed_webhook.dig(:order, :line_items).map { |line_item| line_item.dig(:id) }.compact_blank).present?
        contact_job.lineitems.where(ext_id: deleted_lineitems).destroy_all
      end

      contact_job
    end

    def self.update_job_imports_remaining_count(client, user)
      UserCable.new.broadcast(client, user, { append: 'false', id: 'job_imports_remaining', html: self.job_imports_remaining_string(client.id) })
    end

    # Integration::Servicemonster.update_job_types(client_api_integration: ClientApiIntegration, job_type: String)
    def self.update_job_types(args = {})
      JsonLog.info 'Integration::Servicemonster.update_job_types', { args: }
      return unless args.dig(:client_api_integration).is_a?(ClientApiIntegration) && args.dig(:job_type).to_s.present?
      return if (args[:client_api_integration].job_types || []).include?(args[:job_type].to_s)

      args[:client_api_integration].update(job_types: ((args[:client_api_integration].job_types || []) << args[:job_type].to_s).uniq.sort)
    end

    # Integration::Servicemonster.update_order_subgroups(client_api_integration: ClientApiIntegration, order_subgroup: String)
    def self.update_order_subgroups(args = {})
      JsonLog.info 'Integration::Servicemonster.update_order_subgroups', { args: }
      return unless args.dig(:client_api_integration).is_a?(ClientApiIntegration) && args.dig(:order_subgroup).to_s.present?
      return if (args[:client_api_integration].order_subgroups || []).include?(args[:order_subgroup].to_s)

      args[:client_api_integration].update(order_subgroups: ((args[:client_api_integration].order_subgroups || []) << args[:order_subgroup].to_s).uniq.sort)
    end

    # Integration::Servicemonster.update_order_groups(client_api_integration: ClientApiIntegration, order_group: String)
    def self.update_order_groups(args = {})
      JsonLog.info 'Integration::Servicemonster.update_order_groups', { args: }
      return unless args.dig(:client_api_integration).is_a?(ClientApiIntegration) && args.dig(:order_group).to_s.present?
      return if (args[:client_api_integration].order_groups || []).include?(args[:order_group].to_s)

      args[:client_api_integration].update(order_groups: ((args[:client_api_integration].order_groups || []) << args[:order_group].to_s).uniq.sort)
    end

    def self.update_schedule(contact, parsed_webhook)
      JsonLog.info 'Integration::Servicemonster.update_schedule', { parsed_webhook: }, contact_id: contact.id
      return [nil, nil, parsed_webhook.dig(:appointment, :status).to_s] if parsed_webhook.dig(:order, :id).blank?

      contact_estimate = nil
      contact_job      = nil
      cancelled_status = %w[cancelled unscheduled]

      case parsed_webhook.dig(:order, :type).to_s.downcase
      when 'work order', 'invoice'
        contact_job = self.update_job(contact, parsed_webhook)
      when 'estimate'
        contact_estimate = self.update_estimate(contact, parsed_webhook)
      end

      # update schedule data for both Contacts::Estimate & Contacts::Job
      [contact_estimate, contact_job].compact_blank.each do |contact_table|
        if cancelled_status.include?(parsed_webhook.dig(:appointment, :status).to_s)
          contact_table.update(
            status:                            parsed_webhook.dig(:appointment, :status).to_s,
            scheduled_start_at:                nil,
            scheduled_end_at:                  nil,
            scheduled_arrival_window:          0,
            scheduled_arrival_window_start_at: nil,
            scheduled_arrival_window_end_at:   nil,
            actual_started_at:                 nil,
            actual_completed_at:               nil,
            ext_tech_id:                       ''
          )
        else
          contact_table.update(
            status:                            parsed_webhook.dig(:appointment, :status).to_s,
            scheduled_start_at:                Time.use_zone(contact.client.time_zone) { Chronic.parse(parsed_webhook.dig(:appointment, :scheduled, :start_at).to_s) }&.utc,
            scheduled_end_at:                  Time.use_zone(contact.client.time_zone) { Chronic.parse(parsed_webhook.dig(:appointment, :scheduled, :end_at).to_s) }&.utc,
            scheduled_arrival_window:          parsed_webhook.dig(:appointment, :scheduled, :arrival_window).to_i,
            scheduled_arrival_window_start_at: Time.use_zone(contact.client.time_zone) { Chronic.parse(parsed_webhook.dig(:appointment, :scheduled, :arrival_window_start_at).to_s) }&.utc,
            scheduled_arrival_window_end_at:   Time.use_zone(contact.client.time_zone) { Chronic.parse(parsed_webhook.dig(:appointment, :scheduled, :arrival_window_end_at).to_s) }&.utc,
            actual_started_at:                 Time.use_zone(contact.client.time_zone) { Chronic.parse(parsed_webhook.dig(:appointment, :actual, :started_at).to_s) }&.utc,
            actual_completed_at:               Time.use_zone(contact.client.time_zone) { Chronic.parse(parsed_webhook.dig(:appointment, :actual, :completed_at).to_s) }&.utc,
            ext_tech_id:                       parsed_webhook.dig(:appointment, :ext_tech_id).to_s,
            ext_sales_rep_id:                  parsed_webhook.dig(:appointment, :ext_sales_rep_id).to_s
          )
        end
      end

      [contact_estimate&.id, contact_job&.id, parsed_webhook.dig(:appointment, :status).to_s]
    end

    # validate ServiceMonster credentials
    # Integration::Servicemonster.valid_credentials?
    def self.valid_credentials?(client_api_integration)
      self.credentials_exist?(client_api_integration) && Integrations::ServiceMonster.new(client_api_integration&.credentials)&.valid_credentials?
    end

    # find a webhook using the webhook id
    # Integration::Servicemonster.webhook_by_id(Hash, String)
    def self.webhook_by_id(webhooks, id)
      [webhooks.find { |_k, v| v.dig('id') == id }].compact_blank&.to_h&.deep_symbolize_keys || {}
    end
    # {:order_OnCreated=>
    #   {:id=>"43aae50e-d724-464c-ad9a-3e934ca6bda3",
    #    :events=>
    #     [{:id=>"b61efcb0-d38b-4695-817f-e5f8f1b52aff",
    #       :actions=>{:tag_id=>153, :group_id=>0, :stage_id=>0, :campaign_id=>0, :assign_user_to_technician=>false, :assign_user_to_salesrep=>false},
    #       :criteria=>{:event_new=>false, :commercial=>true, :line_items=>[], :order_type=>"invoice", :residential=>true, :account_types=>[], :event_updated=>false, :account_subtypes=>[]},
    #      },
    #      {:id=>"304ecfc2-c368-4e81-8a13-2fe24155077c",
    #       :actions=>{:tag_id=>144, :group_id=>0, :stage_id=>0, :campaign_id=>0, :assign_user_to_technician=>false, :assign_user_to_salesrep=>false},
    #       :criteria=>{:event_new=>false, :commercial=>true, :line_items=>["f255ab9c-98c1-11ec-8e31-bede7a0a1d0a"], :order_type=>"order", :residential=>true, :account_types=>[], :event_updated=>false, :account_subtypes=>[]},
    #      },
    #      {:id=>"47f319da-fee0-4f5b-beab-979f145d177c",
    #       :actions=>{:tag_id=>149, :group_id=>0, :stage_id=>0, :campaign_id=>0, :assign_user_to_technician=>false, :assign_user_to_salesrep=>false},
    #       :criteria=>{:event_new=>false, :commercial=>true, :line_items=>[], :order_type=>"estimate", :residential=>true, :event_updated=>false},
    #      }]}}

    # find a webhook using any of the event id's
    # Integration::Servicemonster.webhook_by_event_id(Hash, String)
    def self.webhook_by_event_id(webhooks, id)
      [webhooks.find { |_k, v| v.dig('events').find { |x| x.dig('id') == id } }].compact_blank&.to_h&.deep_symbolize_keys || {}
    end
    # {:order_OnCreated=>
    #   {:id=>"43aae50e-d724-464c-ad9a-3e934ca6bda3",
    #    :events=>
    #     [{:id=>"b61efcb0-d38b-4695-817f-e5f8f1b52aff",
    #       :actions=>{:tag_id=>153, :group_id=>0, :stage_id=>0, :campaign_id=>0, :assign_user_to_technician=>false, :assign_user_to_salesrep=>false},
    #       :criteria=>{:event_new=>false, :commercial=>true, :line_items=>[], :order_type=>"invoice", :residential=>true, :account_types=>[], :event_updated=>false, :account_subtypes=>[]},
    #      },
    #      {:id=>"304ecfc2-c368-4e81-8a13-2fe24155077c",
    #       :actions=>{:tag_id=>144, :group_id=>0, :stage_id=>0, :campaign_id=>0, :assign_user_to_technician=>false, :assign_user_to_salesrep=>false},
    #       :criteria=>{:event_new=>false, :commercial=>true, :line_items=>["f255ab9c-98c1-11ec-8e31-bede7a0a1d0a"], :order_type=>"order", :residential=>true, :account_types=>[], :event_updated=>false, :account_subtypes=>[]},
    #      },
    #      {:id=>"47f319da-fee0-4f5b-beab-979f145d177c",
    #       :actions=>{:tag_id=>149, :group_id=>0, :stage_id=>0, :campaign_id=>0, :assign_user_to_technician=>false, :assign_user_to_salesrep=>false},
    #       :criteria=>{:event_new=>false, :commercial=>true, :line_items=>[], :order_type=>"estimate", :residential=>true, :event_updated=>false},
    #      }]}}

    # find a webhook event using the webhook event id
    # Integration::Servicemonster.webhook_event_by_id(Hash, String)
    def self.webhook_event_by_id(webhooks, id)
      webhooks.find { |_k, v| v.dig('events').find { |x| x.dig('id') == id } }&.last&.dig('events')&.find { |x| x.dig('id') == id }&.deep_symbolize_keys || {}
    end
    # {:id=>"b61efcb0-d38b-4695-817f-e5f8f1b52aff",
    #  :actions=>{:tag_id=>153, :group_id=>0, :stage_id=>0, :campaign_id=>0, :assign_user_to_technician=>false, :assign_user_to_salesrep=>false},
    #  :criteria=>{:event_new=>false, :commercial=>true, :line_items=>[], :order_type=>"invoice", :residential=>true, :account_types=>[], :event_updated=>false, :account_subtypes=>[]},
    # }

    # find a webhook object using either a webhook id or webhook event id
    # Integration::Servicemonster.webhook_object_by_id(Hash, String)
    def self.webhook_object_by_id(webhooks, id)
      response = self.webhook_by_id(webhooks, id)&.keys&.first.to_s
      response = webhooks.find { |_k, v| v.dig('events').find { |x| x.dig('id') == id } }&.first.to_s if response.blank?

      response
    end
    # "order_OnCreated"

    # Integration::Servicemonster.webhooks
    def self.webhooks
      [
        { name: 'Account Created', event: 'account_OnCreated', description: 'Account created' },
        { name: 'Account Updated', event: 'account_OnUpdated', description: 'Account updated' },
        { name: 'Account Invoiced', event: 'account_OnInvoiced', description: 'Account invoiced' },
        { name: 'Account Deleted', event: 'account_OnDeleted', description: 'Account deleted' },
        { name: 'Order Created', event: 'order_OnCreated', description: 'Order created' },
        { name: 'Order Updated', event: 'order_OnUpdated', description: 'Order updated' },
        { name: 'Order Invoiced', event: 'order_OnInvoiced', description: 'Order invoiced' },
        { name: 'Order Deleted', event: 'order_OnDeleted', description: 'Order deleted' },
        { name: 'Appointment Created', event: 'appointment_OnCreated', description: 'Appointment Created' },
        { name: 'Appointment Updated', event: 'appointment_OnUpdated', description: 'Appointment updated' },
        { name: 'Appointment Deleted', event: 'appointment_OnDeleted', description: 'Appointment deleted' }
      ]
    end
  end
end

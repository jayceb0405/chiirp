# frozen_string_literal: true

# app/models/integration/callrail/v3/event.rb
module Integration
  module Callrail
    module V3
      class Event
        # initialize CallRail event
        # cr_event_client = Integration::Callrail::V3::Event.new()
        # (req) client_api_integration_id:   (Integer)
        # (req) customer_phone_number:       (String)
        # (req) company_id:                  (String)
        # (req) type:                        (String)
        # (req) call_type:                   (String)
        # (opt) direction:                   (String)
        # (req) tracking_phone_number:       (String)
        # (req) lead_status:                 (String)
        # (req) source_name:                 (String)
        # (opt) tags:                        (Array[String])
        # (opt) keywords:                    (Array[String])
        def initialize(args = {})
          JsonLog.info 'Integration::Callrail::V3::Event.initialize', { args: }
          @company_id                 = args.dig('company_id')
          @type                       = args.dig('type')
          @call_type                  = args.dig('call_type')
          @answered                   = args.dig('answered')
          @direction                  = args.dig('direction')
          @keywords                   = args.dig('keywords') || ''
          @lead_status                = args.dig('lead_status')
          @source_name                = args.dig('source_name')
          @tags                       = args.dig('tags') || []

          @customer_name              = args.dig('customer_name')
          @customer_city              = args.dig('customer_city')
          @customer_state             = args.dig('customer_state')
          @customer_country           = args.dig('customer_country')

          @form_data                  = args.dig('form_data') || {}
          @resource_id                = args.dig('resource_id')

          @client_api_integration_id  = args.dig('client_api_integration_id')
          @client_api_integration     = ClientApiIntegration.find_by(id: @client_api_integration_id)

          @customer_phone_number      = args.dig('customer_phone_number')&.clean_phone(@client_api_integration.client.primary_area_code)
          @tracking_phone_number      = args.dig('tracking_phone_number')&.clean_phone(@client_api_integration.client.primary_area_code)

          @raw_params                 = args.dig('raw_params')
        end

        # process the event received from CallRail
        # cr_event_client.process
        def process
          return unless ok_to_process

          # parse form submission event
          parse_form_submission if @type == 'form_submission'

          # create a contact
          phones = { @customer_phone_number => 'mobile' } if @customer_phone_number
          contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, phones:)

          # update contact info if:
          #   new record; since there would be no data yet
          #   form_data contact info is present; this indicates the contact filled in this info
          # we don't do this by default because the callrail data is based on phone records and can be imprecise and unreliable
          if contact.new_record? || %w[address_addr1 address_addr2 address_city address_state address_zip].include?(@form_data.keys)
            contact.firstname = @customer_name.parse_name[:firstname] if @customer_name
            contact.lastname = @customer_name.parse_name[:lastname] if @customer_name
            contact.address1 = @form_data['address_addr1'] if @form_data['address_addr1']
            contact.address2 = @form_data['address_addr2'] if @form_data['address_addr2']
            contact.city = @customer_city if @customer_city
            contact.state = @customer_state if @customer_state
            contact.zipcode = @form_data['address_zip'] if @form_data['address_zip']
            contact.save
          end

          @tags.each do |tag|
            Contacts::Tags::ApplyByNameJob.perform_now(
              contact_id: contact.id,
              tag_name:   tag
            )
          end

          # save raw param data
          contact.raw_posts.create(ext_source: 'callrail', ext_id: 'callcompleted', data: @raw_params)

          # filter events by the type. include blank to support older events that never got type set
          @client_api_integration.events.filter { |event| event['type'] == @type || event['type'].blank? }.each { |event| process_event(event.deep_symbolize_keys, contact) }
        end

        private

        def ok_to_process
          @client_api_integration.present? && @type.present?
        end

        def parse_form_submission
          @customer_phone_number ||= @form_data['phone_number'] if @form_data['phone_number']
          @customer_name ||= @form_data['your_name'] if @form_data['your_name']
          @customer_city ||= @form_data['address_city'] if @form_data['address_city']
          @customer_state ||= @form_data['address_state'] if @form_data['address_state']
        end

        # process a chiirp client integration event
        # (req) event:     (Hash)
        def process_event(event, contact)
          JsonLog.info 'Integration::Callrail::V3::Event.process_event', { event: }, contact_id: contact&.id
          return unless contact
          return unless ok_company?(event)
          return unless not_ok_call_types?(event)
          return unless not_ok_keywords?(event)
          return unless not_ok_tracking_numbers?(event)
          return unless not_ok_lead_statuses?(event)
          return unless not_ok_source_names?(event)
          return unless not_ok_tag_include_ids?(event)
          return if ok_tag_exclude_ids?(event)
          return unless ok_answered?(event)
          return unless ok_form_name?(event)

          contact.process_actions(
            campaign_id:       event.dig(:action, :campaign_id).to_i,
            group_id:          event.dig(:action, :group_id).to_i,
            stage_id:          event.dig(:action, :stage_id).to_i,
            tag_id:            event.dig(:action, :tag_id).to_i,
            stop_campaign_ids: event.dig(:action, :stop_campaign_ids)&.compact_blank
          )
        end

        def ok_answered?(event)
          return true unless @type == 'outbound_post_call' # we only care in outbound post calls
          return true if event[:answered].nil? # we don't care what answered is set to

          event[:answered] == @answered.to_bool
        end

        def ok_company?(event)
          _, event_company_id = Integration::Callrail::V3::Base.split_account_company_id(event[:account_company_id])
          event_company_id == @company_id
        end

        def ok_form_name?(event)
          return true unless @type == 'form_submission'
          return true if event[:form_names].nil?

          event[:form_names].include?(form_name(event[:account_company_id], @resource_id))
        end

        def form_name(account_company_id, id)
          account_id, company_id = Integration::Callrail::V3::Base.split_account_company_id(account_company_id)
          cr_client = Integrations::CallRail::V3::Base.new(@client_api_integration.credentials, account_id:, company_id:)
          form_submission = cr_client.form_submission(company_id, id)
          form_submission.nil? ? 'Unknown' : form_submission[:form_name]
        end

        def not_ok_call_types?(event)
          event[:call_types]&.any? ? event.dig(:call_types).include?(@call_type) : true
        end

        def not_ok_keywords?(event)
          event[:keywords]&.any? ? event.dig(:keywords).any? { |keyword| @keywords.include?(keyword) } : true
        end

        def not_ok_tracking_numbers?(event)
          event[:tracking_phone_numbers]&.any? ? event.dig(:tracking_phone_numbers).include?(@tracking_phone_number) : true
        end

        def not_ok_lead_statuses?(event)
          event[:lead_statuses]&.any? ? event.dig(:lead_statuses).include?(@lead_status) : true
        end

        def not_ok_source_names?(event)
          event[:source_names]&.any? ? event.dig(:source_names).include?(@source_name) : true
        end

        def not_ok_tag_include_ids?(event)
          event[:include_tags]&.any? ? event.dig(:include_tags).any? { |tag| @tags.include?(tag) } : true
        end

        def ok_tag_exclude_ids?(event)
          event[:exclude_tags]&.any? ? event.dig(:exclude_tags)&.any? { |tag| @tags.include?(tag) } : false
        end
      end
    end
  end
end

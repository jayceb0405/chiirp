# frozen_string_literal: true

# app/lib/integrations/job_nimbus.rb
module Integrations
  # process various API calls to JobNimbus
  class JobNimbusSave
    attr_reader :error, :message, :result

    # DEPRECATED
    # initialize Integrations::JobNimbus object
    # jn_client = Integrations::JobNimbus.new(String)
    def initialize(api_key = '')
      reset_attributes
      @result  = nil
      @api_key = api_key
    end

    # jn_client.contact(String)
    def contact(jnid = '')
      reset_attributes
      @result = {}

      if jnid.blank?
        @message = 'JobNimbus contact ID is required.'
        return @result
      end

      jobnimbus_request(
        body:                  nil,
        error_message_prepend: 'Integrations::JobNimbus.contact',
        method:                'get',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/contacts/#{jnid}"
      )
    end

    # call JobNimbus API to retrieve contacts
    # jn_client.contacts(page_size: Integer, page_index: Integer)
    def contacts(args = {})
      reset_attributes
      @result = []

      page_size   = (args.dig(:page_size) || 25).to_i
      page_index  = (args.dig(:page_index) || 0).to_i

      jobnimbus_request(
        body:                  nil,
        error_message_prepend: 'Integrations::JobNimbus.contacts',
        method:                'get',
        params:                {
          size: page_size,
          from: page_index
        },
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/contacts"
      )
    end

    # call JobNimbus API to retrieve the number of contacts
    # jn_client.contacts_count
    def contacts_count
      reset_attributes
      @result = {}

      @result = jobnimbus_request(
        body:                  nil,
        error_message_prepend: 'Integrations::JobNimbus.contacts_count',
        method:                'get',
        params:                {
          limit:     1,
          pageIndex: 0
        },
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/contacts"
      ).dig(:count) || 0
    end

    # jn_client.job(String)
    def job(jnid = '')
      reset_attributes
      @result = {}

      if jnid.blank?
        @message = 'JobNimbus job ID is required.'
        return @result
      end

      jobnimbus_request(
        body:                  nil,
        error_message_prepend: 'Integrations::JobNimbus.job',
        method:                'get',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/jobs/#{jnid}"
      )
    end

    # parse & normalize data from webhook
    # rb_client.parse_webhook(params)
    def parse_webhook(args = {})
      @success = true

      {
        event_status: "#{args.dig(:type)}_#{args.dig(:status_name)}",
        contact:      parse_contact_from_webhook(args),
        estimate:     parse_estimate_from_webhook(args),
        job:          parse_job_from_webhook(args),
        invoice:      parse_invoice_from_webhook(args),
        workorder:    parse_workorder_from_webhook(args),
        task:         parse_task_from_webhook(args)
      }
    end

    # push Contact into JobNimbus contacts
    # jn_client.push_contact_to_jobnimbus(contact: Contact)
    def push_contact_to_jobnimbus(args = {})
      contact = args.dig(:contact)
      @result = {}

      unless contact.is_a?(Hash)
        @message = 'Contact data is required.'
        return @result
      end

      body = {
        first_name:    contact.dig(:firstname).to_s,
        last_name:     contact.dig(:lastname).to_s,
        email:         contact.dig(:email).to_s,
        address_line1: contact.dig(:address1).to_s,
        address_line2: contact.dig(:address2).to_s,
        city:          contact.dig(:city).to_s,
        state_text:    contact.dig(:state).to_s,
        zip:           contact.dig(:zipcode).to_s,
        company:       contact.dig(:companyname).to_s
      }

      contact.dig(:phones) || {}.each do |label, number|
        body[:mobile_phone] = number if label.include?('mobile')
        body[:home_phone]   = number if label.include?('home')
        body[:work_phone]   = number if label.include?('work')
        body[:fax_number]   = number if label.include?('fax')
      end

      jobnimbus_request(
        body:,
        error_message_prepend: 'Integrations::JobNimbus.push_contact_to_jobnimbus',
        method:                'post',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/contacts"
      )
    end

    def success?
      @success
    end

    private

    def base_api_url
      'https://app.jobnimbus.com'
    end

    def base_api_version
      'api1'
    end

    def jobnimbus_request(args = {})
      reset_attributes
      body                  = args.dig(:body)
      error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::JobNimbus.jobnimbus_request'
      faraday_method        = (args.dig(:method) || 'get').to_s
      params                = args.dig(:params)
      @result               = args.dig(:default_result)
      url                   = args.dig(:url).to_s

      if @api_key.blank?
        @error_message = 'JobNimbus API key is required.'
        return @result
      elsif url.blank?
        @error_message = 'JobNimbus API URL is required.'
        return @result
      end

      record_api_call(error_message_prepend)

      success, error, message = Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        error_message_prepend:,
        current_variables:     {
          parent_body:                  args.dig(:body),
          parent_error_message_prepend: args.dig(:error_message_prepend),
          parent_method:                args.dig(:method),
          parent_params:                args.dig(:params),
          parent_result:                args.dig(:default_result),
          parent_url:                   args.dig(:url),
          parent_file:                  __FILE__,
          parent_line:                  __LINE__
        }
      ) do
        faraday_result = Faraday.send(faraday_method, url) do |req|
          req.headers['Authorization'] = "Bearer #{@api_key}"
          req.headers['Content-Type']  = 'application/json'
          req.params                   = params if params.present?
          req.body                     = body.to_json if body.present?
        end

        # Rails.logger.info "faraday_result: #{faraday_result.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

        case faraday_result.status
        when 200
          result   = JSON.parse(faraday_result.body)
          @result  = if result.respond_to?(:deep_symbolize_keys)
                       result.deep_symbolize_keys
                     elsif result.respond_to?(:map)
                       result.map(&:deep_symbolize_keys)
                     else
                       result
                     end
          @success = true
        when 401, 404
          @message = "#{faraday_result.reason_phrase}: #{faraday_result.body}"
          @success = false
        else
          @message = "#{faraday_result.reason_phrase}: #{faraday_result.body}"
          @success = false

          ProcessError::Report.send(
            error_message: "#{error_message_prepend}: #{@message}",
            variables:     {
              faraday_result:         faraday_result.inspect,
              faraday_result_methods: faraday_result&.methods.inspect,
              result:                 @result.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      end

      @success = false unless success
      @error   = error
      @message = message if message.present?

      # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
      Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

      @result
    end

    # parse/normalize Contact data from webhook
    def parse_contact_from_webhook(args = {})
      jn_contact = case args.dig(:type).to_s
                   when 'contact'
                     args
                   when 'estimate', 'job', 'invoice', 'workorder', 'task'

                     if (contact_jnid = (args.dig(:primary, :id) || args.dig(:related)&.find { |r| r.dig(:type).to_s == 'contact' }&.dig(:id)).to_s)
                       self.contact(contact_jnid)
                     else
                       {}
                     end
                   else
                     {}
                   end

      response = {
        id:              jn_contact.dig(:jnid).to_s,
        company:         jn_contact.dig(:company).to_s,
        firstname:       jn_contact.dig(:first_name).to_s,
        lastname:        jn_contact.dig(:last_name).to_s,
        address_01:      jn_contact.dig(:address_line1).to_s,
        address_02:      jn_contact.dig(:address_line2).to_s,
        city:            jn_contact.dig(:city).to_s,
        state:           jn_contact.dig(:state_text).to_s,
        zipcode:         jn_contact.dig(:zip).to_s,
        email:           jn_contact.dig(:email).to_s,
        status:          jn_contact.dig(:status_name).to_s,
        sales_rep:       jn_contact.dig(:sales_rep).to_s,
        sales_rep_name:  jn_contact.dig(:sales_rep_name).to_s,
        sales_rep_email: jn_contact.dig(:sales_rep_email).to_s,
        phones:          {}
      }

      response[:phones][jn_contact[:mobile_phone].to_s] = 'mobile' if jn_contact.dig(:mobile_phone).present?
      response[:phones][jn_contact[:home_phone].to_s]   = 'home' if jn_contact.dig(:home_phone).present?
      response[:phones][jn_contact[:work_phone].to_s]   = 'work' if jn_contact.dig(:work_phone).present?
      response[:phones][jn_contact[:fax_number].to_s]   = 'fax' if jn_contact.dig(:fax_number).present?

      response
    end

    # parse/normalize Estimate data from webhook
    def parse_estimate_from_webhook(args = {})
      if args.dig(:type).to_s == 'estimate'
        {
          id:         args.dig(:jnid).to_s,
          number:     args.dig(:number).to_s,
          status:     args.dig(:status_name).to_s,
          type:       args.dig(:type).to_s,
          date_start: args.dig(:date_start).to_i.positive? ? Time.at(args.dig(:date_start)).utc : nil,
          date_end:   args.dig(:date_end).to_i.positive? ? Time.at(args.dig(:date_end)).utc : nil,
          notes:      args.dig(:internal_note).to_s
        }
      else
        {}
      end
    end

    # parse/normalize Job data from webhook
    def parse_job_from_webhook(args = {})
      if args.dig(:type).to_s == 'job'
        {
          id:          args.dig(:jnid).to_s,
          date_start:  args.dig(:date_start).to_i.positive? ? Time.at(args.dig(:date_start)).utc : nil,
          date_end:    args.dig(:date_end).to_i.positive? ? Time.at(args.dig(:date_end)).utc : nil,
          description: args.dig(:description).to_s,
          number:      args.dig(:number).to_s,
          status:      args.dig(:status_name).to_s,
          tags:        args.dig(:tags).to_s,
          type:        args.dig(:type).to_s
        }
      else
        {}
      end
    end

    # parse/normalize Invoice data from webhook
    def parse_invoice_from_webhook(args = {})
      if args.dig(:type).to_s == 'invoice'
        {
          id:     args.dig(:jnid).to_s,
          number: args.dig(:number).to_s,
          status: args.dig(:status_name).to_s,
          type:   args.dig(:type).to_s,
          notes:  args.dig(:internal_note).to_s
        }
      else
        {}
      end
    end

    # parse/normalize Task data from webhook
    def parse_task_from_webhook(args = {})
      if args.dig(:type).to_s == 'task'
        {
          id:         args.dig(:jnid).to_s,
          number:     args.dig(:number).to_s,
          title:      args.dig(:title).to_s,
          type:       args.dig(:record_type_name).to_s,
          date_start: args.dig(:date_start).to_i.positive? ? Time.at(args.dig(:date_start)).utc : nil,
          date_end:   args.dig(:date_end).to_i.positive? ? Time.at(args.dig(:date_end)).utc : nil,
          completed:  args.dig(:is_completed).to_bool
        }
      else
        {}
      end
    end

    # parse/normalize Work Order data from webhook
    def parse_workorder_from_webhook(args = {})
      if args.dig(:type).to_s == 'workorder'
        {
          id:         args.dig(:jnid).to_s,
          number:     args.dig(:number).to_s,
          status:     args.dig(:status_name).to_s,
          type:       args.dig(:type).to_s,
          date_start: args.dig(:date_start).to_i.positive? ? Time.at(args.dig(:date_start)).utc : nil,
          date_end:   args.dig(:date_end).to_i.positive? ? Time.at(args.dig(:date_end)).utc : nil,
          notes:      args.dig(:internal_note).to_s
        }
      else
        {}
      end
    end

    def record_api_call(error_message_prepend)
      Clients::ApiCall.create(target: 'jobnimbus', client_api_id: @api_key, api_call: error_message_prepend)
    end

    def reset_attributes
      @error       = 0
      @message     = ''
      @success     = false
    end
  end
end

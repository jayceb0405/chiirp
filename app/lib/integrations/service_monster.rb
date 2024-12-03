# frozen_string_literal: true

# app/lib/integrations/service_monster.rb
module Integrations
  class ServiceMonster
    class ServiceMonsterError < StandardError; end

    attr_reader :error, :faraday_result, :message, :result

    # initialize Integrations::ServiceMonster object
    # sm_client = Integrations::ServiceMonster.new({ userName: String, password: String, sub_integration: String })
    #   (req) userName:        (String)
    #   (req) password:        (String)
    #   (opt) sub_integration: (String)
    def initialize(credentials)
      reset_attributes
      @password        = credentials&.symbolize_keys&.dig(:password)
      @result          = nil
      @username        = credentials&.symbolize_keys&.dig(:userName)
      @sub_integration = credentials&.symbolize_keys&.dig(:sub_integration).to_s

      if @password.blank? || @username.blank?
        @message   = 'Invalid ServiceMonster credentials!'
        @success   = false
      else
        @success   = true
      end
    end

    # call ServiceMonster API to retrieve accounts
    # sm_client.account(account_id)
    #   (req) account_id: (String)
    def account(account_id)
      reset_attributes
      @result = {}

      if account_id.blank?
        @message = 'ServiceMonster account ID is required.'
        return @result
      end

      servicemonster_request(
        body:                  nil,
        error_message_prepend: 'Integrations::ServiceMonster::Account',
        method:                'get',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/accounts/#{account_id}"
      )
    end

    # call ServiceMonster API to retrieve accounts
    # sm_client.accounts(page_size: Integer, page_index: Integer)
    #   (opt) count_only:  (Boolean)
    #   (opt) page_index:  (Integer)
    #   (opt) page_size:   (Integer)
    def accounts(args = {})
      reset_attributes
      count_only  = args.dig(:count_only).to_bool
      page_index  = count_only ? 0 : [args.dig(:page_index).to_i, 0].max
      page_size   = count_only ? 1 : (args.dig(:page_size) || self.default_page_size).to_i
      params      = {
        limit:     page_size,
        pageIndex: page_index
      }

      servicemonster_request(
        body:                  nil,
        error_message_prepend: 'Integrations::ServiceMonster::Accounts',
        method:                'get',
        params:,
        default_result:        [],
        url:                   "#{base_api_url}/#{base_api_version}/accounts"
      )

      @result = if count_only
                  @result.is_a?(Hash) ? @result.dig(:count).to_i : 0
                else
                  @result.is_a?(Hash) ? @result.dig(:items) : []
                end
    end

    # call ServiceMonster API to retrieve the number of accounts
    # sm_client.accounts_count
    def accounts_count(args = {})
      @result = self.accounts(args.merge({ count_only: true }))
    end

    # call ServiceMonster API to authenticate a new Client request ID
    # sm_client.authenticate_request_id(request_id)
    def authenticate_request_id(request_id)
      reset_attributes
      @result = {}

      if request_id.blank?
        @message = 'ServiceMonster request ID is required.'
        return @result
      end

      servicemonster_request(
        body:                  nil,
        error_message_prepend: 'Integrations::ServiceMonster::AuthenticateRequestId',
        method:                'get',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/apiRequests/#{app_id}/#{request_id}"
      )
    end

    # call ServiceMonster API to retrieve company info
    # sm_client.company
    def company
      reset_attributes
      @result = []

      servicemonster_request(
        body:                  nil,
        error_message_prepend: 'Integrations::ServiceMonster::Company',
        method:                'get',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/company"
      )
    end

    # call ServiceMonster API to request credentials for new Client (after authenticating request ID)
    # sm_client.credentials(request_id)
    def credentials(request_id)
      reset_attributes
      @result = {}

      if request_id.blank?
        @message = 'ServiceMonster request ID is required.'
        return @result
      end

      servicemonster_request(
        body:                  {
          requestID: request_id,
          appID:     app_id
        },
        error_message_prepend: 'Integrations::ServiceMonster::Credentials',
        method:                'post',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/apiRequests/#{app_id}/#{request_id}"
      )
    end

    # default page size for all API calls
    # sm_client.default_page_size
    def default_page_size
      25
    end

    # call ServiceMonster API to unsubscribe from a webhook
    # sm_client.deprovision_webhook(webhook_id)
    def deprovision_webhook(webhook_id)
      @result = ''

      if webhook_id.blank?
        @message = 'Webhook ID is required.'
        return @result
      end

      @result = servicemonster_request(
        body:                  {
          target_url: Rails.application.routes.url_helpers.integrations_servicemonster_endpoint_url(webhook_id, host:)
        },
        error_message_prepend: 'Integrations::ServiceMonster::ProvisionWebhook',
        method:                'post',
        params:                nil,
        default_result:        '',
        url:                   "#{base_webhook_url}/subscriptions/unsubscribe"
      )
    end

    # call ServiceMonster API for one employees
    # sm_client.employee(String)
    def employee(employee_id)
      reset_attributes
      @result = {}

      if employee_id.blank?
        @message = 'ServiceMonster employee ID is required.'
        return @result
      end

      servicemonster_request(
        body:                  nil,
        error_message_prepend: 'Integrations::ServiceMonster::Employee',
        method:                'get',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/employees/#{employee_id}"
      )
    end

    # call ServiceMonster API for all employees
    # sm_client.employees
    def employees
      response = []

      page_size   = self.default_page_size
      page_index  = 0
      page_count  = 1

      while page_index < page_count
        result = servicemonster_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceMonster::Employees',
          method:                'get',
          params:                {
            limit:     page_size,
            pageIndex: page_index,
            wField:    'active',
            wValue:    true
          },
          default_result:        {},
          url:                   "#{base_api_url}/#{base_api_version}/employees"
        )

        response   += result.dig(:items) || []
        page_index += 1
        page_count  = (result.dig(:count).to_f / page_size).ceil
      end

      @result = response
    end

    # get a ServiceMonster job
    # sm_client.job(job_id)
    def job(job_id)
      reset_attributes
      @result = {}

      if job_id.blank?
        @message = 'ServiceMonster Job ID is required.'
        return @result
      end

      servicemonster_request(
        body:                  nil,
        error_message_prepend: 'Integrations::ServiceMonster::Job',
        method:                'get',
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/jobs/#{job_id}"
      )

      @result
    end

    # get ServiceMonster jobs (appointments)
    # sm_client.jobs()
    def jobs(args = {})
      count_only  = args.dig(:count_only).to_bool
      order_id    = args.dig(:order_id).to_s
      page        = count_only ? 0 : [args.dig(:page).to_i, 0].max
      page_size   = count_only ? 1 : (args.dig(:page_size) || self.default_page_size).to_i
      date_min    = args.dig(:date_min)
      date_type   = (args.dig(:date_type) || 'start').to_s.titleize
      @result     = count_only ? 0 : []

      params             = {}
      params[:limit]     = page_size
      params[:pageIndex] = page

      if date_min.respond_to?(:iso8601)
        params[:wField]    = "estDateTime#{date_type}"
        params[:wValue]    = date_min.utc.iso8601
        params[:wOperator] = 'gt'
      elsif order_id.present?
        params[:wField]    = 'orderID'
        params[:wValue]    = order_id
      end

      result = servicemonster_request(
        body:                  nil,
        error_message_prepend: 'Integrations::ServiceMonster::Jobs',
        method:                'get',
        params:,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/jobs"
      )

      @result = if count_only
                  result.dig(:count).to_i
                else
                  result.dig(:items)
                end
    end

    # get the total number of ServiceMonster jobs
    # sm_client.jobs_count()
    def jobs_count(args = {})
      @result = self.jobs(args.merge({ count_only: true }))
    end

    # call ServiceMonster API to retrieve a list of Line Items
    # sm_client.line_items
    def line_items
      response = []

      page_size   = self.default_page_size
      page_index  = 0
      page_count  = 1

      while page_index < page_count
        result = servicemonster_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceMonster::LineItems',
          method:                'get',
          params:                {
            limit:     page_size,
            pageIndex: page_index,
            wField:    'active',
            wValue:    true
          },
          default_result:        {},
          url:                   "#{base_api_url}/#{base_api_version}/orderitems"
        )

        response   += result.dig(:items) || []
        page_index += 1
        page_count  = (result.dig(:count).to_f / page_size).ceil
      end

      @result = response
    end

    # call ServiceMonster API for all Lead Sources
    # sm_client.lead_sources
    #
    # rubocop:disable Style/OptionalBooleanParameter
    def lead_sources(active_only = true)
      # rubocop:enable Style/OptionalBooleanParameter
      reset_attributes
      response = []

      page_size   = self.default_page_size
      page_index  = 0
      page_count  = 1
      params      = {
        limit: page_size
      }

      if active_only
        params[:wField] = 'active'
        params[:wValue] = true
      end

      while page_index < page_count
        params[:pageIndex] = page_index

        result = servicemonster_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceMonster::LeadSources',
          method:                'get',
          params:,
          default_result:        @result,
          url:                   "#{base_api_url}/#{base_api_version}/leadsources"
        )

        response   += result.dig(:items) || []
        page_index += 1
        page_count  = (result.dig(:count).to_f / page_size).ceil
      end

      @result = response
    end

    # call ServiceMonster API for one order
    # sm_client.order(String)
    def order(order_id)
      reset_attributes
      @result = {}

      if order_id.blank?
        @message = 'ServiceMonster order ID is required.'
        return @result
      end

      servicemonster_request(
        body:                  nil,
        error_message_prepend: 'Integrations::ServiceMonster::Order',
        method:                'get',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/orders/#{order_id}"
      )
    end

    # get ServiceMonster orders
    # sm_client.orders
    # (opt) count_only:  (Boolean)
    # (opt) date_min:    (DateTime)
    # (opt) date_type:   (String)
    # (opt) page:        (Integer)
    # (opt) page_size:   (Integer)
    def orders(args = {})
      count_only  = args.dig(:count_only).to_bool
      date_min    = args.dig(:date_min)
      date_type   = args.dig(:date_type).to_s == 'actual' ? 'actual' : 'est'
      page        = count_only ? 0 : [args.dig(:page).to_i, 0].max
      page_size   = count_only ? 1 : (args.dig(:page_size) || self.default_page_size).to_i
      @result     = count_only ? 0 : []

      params      = {
        limit:     page_size,
        pageIndex: page
      }

      if date_min.respond_to?(:iso8601)
        params[:wField]    = "#{date_type}DateTimeStart"
        params[:wValue]    = date_min.utc.iso8601
        params[:wOperator] = 'gt'
      end

      servicemonster_request(
        body:                  nil,
        error_message_prepend: 'Integrations::ServiceMonster::Orders',
        method:                'get',
        params:,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/orders"
      )

      @result = if @result.is_a?(Hash)
                  count_only ? @result.dig(:count).to_i : @result.dig(:items)
                else
                  count_only ? 0 : []
                end
    end

    # get the total number of ServiceMonster orders
    # sm_client.orders_count()
    def orders_count(args = {})
      @result = self.orders(args.merge({ count_only: true }))
    end

    # sm_client.parse_order_webhook(params)
    def parse_webhook(args = {})
      company_id   = args.dig(:company_id).to_s
      event_object = args.dig(:event_object).to_s # account, order, appointment
      event_type   = args.dig(:event_type).to_s # OnCreated, OnUpdated, OnArchived, OnDeleted, OnInvoiced

      response = {
        event:         "#{event_object}_#{event_type}",
        company_id:,
        success:       false,
        contact:       {},
        order:         {},
        appointment:   {},
        error_code:    '',
        error_message: ''
      }

      case event_object
      when 'account'
        response[:success] = true
        response[:contact] = parse_contact_from_webhook(event_object:, event_type:, params: args.dig(:params))
      when 'order'
        response[:success] = true
        response[:contact] = parse_contact_from_webhook(event_object:, event_type:, params: args.dig(:params))
        response[:order]   = parse_order_from_webhook(event_object:, event_type:, params: args.dig(:params))
        response[:site]    = parse_site_from_webhook(event_object:, event_type:, params: args.dig(:params))
      when 'appointment'
        response[:success]     = true
        response[:contact]     = parse_contact_from_webhook(event_object:, event_type:, params: args.dig(:params))
        response[:order]       = parse_order_from_webhook(event_object:, event_type:, params: args.dig(:params))
        response[:site]        = parse_site_from_webhook(event_object:, event_type:, params: args.dig(:params), order: response[:order])
        response[:appointment] = parse_appointment_from_webhook(event_object:, event_type:, params: args.dig(:params))
      else
        response[:error_message] = 'Unknown webhook event received.'
      end

      response
    end

    # call ServiceMonster API to subscribe to a webhook
    # sm_client.provision_webhook(event_object: String, event_type: String)
    def provision_webhook(args = {})
      event_object = args.dig(:event_object).to_s
      event_type   = args.dig(:event_type).to_s
      webhook_id   = (args.dig(:webhook_id) || webhook_guid).to_s
      @result = {}

      if event_object.blank?
        @message = 'Event object is required.'
        return @result
      elsif event_type.blank?
        @message = 'Event type is required.'
        return @result
      end

      @result = servicemonster_request(
        body:                  {
          event:      "#{event_object}_#{event_type}",
          target_url: Rails.application.routes.url_helpers.integrations_servicemonster_endpoint_url(webhook_id, host:)
        },
        error_message_prepend: 'Integrations::ServiceMonster::ProvisionWebhook',
        method:                'post',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_webhook_url}/subscriptions/subscribe"
      ).merge({ webhook_id: })
    end

    # push Contact into ServiceMonster accounts
    # sm_client.push_contact_to_servicemonster(contact: Contact)
    def push_contact_to_servicemonster(args = {})
      contact = args.dig(:contact)
      @result = {}

      unless contact.is_a?(Hash)
        @message = 'Contact data is required.'
        return @result
      end

      servicemonster_request(
        body:                  {
          accountName: Friendly.new.fullname(contact.dig(:firstname).to_s, contact.dig(:lastname).to_s),
          firstName:   contact.dig(:firstname).to_s,
          lastName:    contact.dig(:lastname).to_s,
          email:       contact.dig(:email).to_s,
          phone1:      contact.dig(:phone).to_s,
          phone1Label: 'Mobile',
          address1:    contact.dig(:address1).to_s,
          address2:    contact.dig(:address2).to_s,
          city:        contact.dig(:city).to_s,
          state:       contact.dig(:state).to_s,
          zip:         contact.dig(:zipcode).to_s
        },
        error_message_prepend: 'Integrations::ServiceMonster::PushContactToServicemonster',
        method:                'post',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/accounts"
      )
    end

    # call ServiceMonster API to retrieve a Site
    # sm_client.site(site_id)
    # (req) site_id: (String)
    def site(site_id)
      reset_attributes
      @result = {}

      if site_id.blank?
        @message = 'ServiceMonster site ID is required.'
        return @result
      end

      servicemonster_request(
        body:                  nil,
        error_message_prepend: 'Integrations::ServiceMonster::Site',
        method:                'get',
        params:                nil,
        default_result:        @result,
        url:                   "#{base_api_url}/#{base_api_version}/sites/#{site_id}"
      )
    end

    def success?
      @success
    end

    # validate ServiceMonster credentials
    # sm_client.validate_credentials
    def valid_credentials?
      @password.present? && @username.present? && self.company.present?
    end

    # sm_client.webhook_active?(webhook_id)
    def webhook_active?(webhook_id)
      self.webhooks.find { |w| w.dig(:targetURL).to_s.include?(webhook_id) }&.dig(:active)&.to_bool
    end

    # call ServiceMonster API to retreive a list of webhooks
    # sm_client.webhooks
    def webhooks
      response = []

      page_size   = self.default_page_size
      page_index  = 0
      page_count  = 1

      while page_index < page_count
        result = servicemonster_request(
          body:                  nil,
          error_message_prepend: 'Integrations::ServiceMonster::Webhooks',
          method:                'get',
          params:                {
            limit:     page_size,
            pageIndex: page_index
          },
          default_result:        {},
          url:                   "#{base_webhook_url}/subscriptions"
        )

        response   += result.dig(:items) || []
        page_index += 1
        page_count  = (result.dig(:totalCount).to_f / page_size).ceil
      end

      @result = response
    end

    private

    def app_id
      case @sub_integration
      when 'ontrack'
        Rails.application.credentials[:servicemonster][:on_track][:app_id]
      else
        Rails.application.credentials[:servicemonster][:app_id]
      end
    end

    def base_api_url
      'https://api.servicemonster.net'
    end

    def base_webhook_url
      'https://webapi.servicemonster.net/api/resthooks'
    end

    def base_api_version
      'v1'
    end

    def basic_auth
      Base64.urlsafe_encode64("#{username}:#{password}").strip
    end

    def host
      I18n.t("tenant.#{Rails.env}.app_host")
    end

    def password
      @password ||= Rails.application.credentials[:servicemonster][:password]
    end

    def parse_appointment_from_webhook(args = {})
      ext_tech_id      = ''
      ext_sales_rep_id = ''

      (args.dig(:params, :assignedEmployeeIDs) || []).each do |employee_id|
        sm_employee = self.employee(employee_id)

        ext_tech_id      = employee_id if sm_employee.dig(:isTechnician).to_bool
        ext_sales_rep_id = employee_id if sm_employee.dig(:isSalesRep).to_bool
      end

      sm_job = self.job(args.dig(:params, :jobID))

      if sm_job.dig(:arrivalWindow).present? && args.dig(:params, :estDateTimeStart).present? && args[:params][:estDateTimeStart].respond_to?(:to_datetime)
        arrival_window_start_at = begin
          Chronic.parse("#{args[:params][:estDateTimeStart].to_datetime.strftime('%m/%d/%Y')} #{sm_job[:arrivalWindow].to_s.split(' - ').first}")
        rescue StandardError
          nil
        end
        arrival_window_end_at = begin
          Chronic.parse("#{args[:params][:estDateTimeStart].to_datetime.strftime('%m/%d/%Y')} #{sm_job[:arrivalWindow].to_s.split(' - ').last}")
        rescue StandardError
          nil
        end
      else
        arrival_window_start_at = nil
        arrival_window_end_at   = nil
      end

      {
        id:               args.dig(:params, :jobID),
        status:           args.dig(:params, :jobStatus).to_s.downcase,
        job_type:         args.dig(:params, :jobType).to_s,
        scheduled:        {
          start_at:                args.dig(:params, :estDateTimeStart).to_s,
          end_at:                  args.dig(:params, :estDateTimeEnd).to_s,
          arrival_window:          (((arrival_window_end_at || 0) - (arrival_window_start_at || 0)) / 60).to_i,
          arrival_window_start_at: arrival_window_start_at&.strftime('%Y-%m-%dT%T'),
          arrival_window_end_at:   arrival_window_end_at&.strftime('%Y-%m-%dT%T')
        },
        actual:           {
          started_at:   args.dig(:params, :actualDateTimeStart).to_s,
          completed_at: args.dig(:params, :actualDateTimeEnd).to_s
        },
        ext_tech_id:,
        ext_sales_rep_id:
      }
    end

    def parse_contact_from_webhook(args = {})
      if args.dig(:event_object).to_s.casecmp?('account') && args.dig(:event_type).to_s.casecmp?('ondeleted')
        response = {
          id:              args.dig(:params, :accountID).to_s,
          lastname:        args.dig(:params, :lastName).to_s,
          firstname:       args.dig(:params, :firstName).to_s,
          email:           args.dig(:params, :email).to_s,
          companyname:     '',
          address_01:      '',
          address_02:      '',
          city:            '',
          state:           '',
          postal_code:     '',
          country:         '',
          commercial:      args.dig(:params, :commercial).to_bool,
          account_type:    args.dig(:params, :accountType).to_s,
          account_subtype: args.dig(:params, :accountSubType).to_s,
          phones:          {},
          lead_source_id:  ''
        }

        response[:phones][args.dig(:params, :fax).to_s.clean_phone] = 'fax' if args.dig(:params, :fax).present?
        response[:phones][args.dig(:params, :phone1).to_s.clean_phone] = args.dig(:params, :phone1Label).to_s.downcase.gsub('phone', '').strip if args.dig(:params, :phone1).present? && args.dig(:params, :phone1Label).present?
        response[:phones][args.dig(:params, :phone2).to_s.clean_phone] = args.dig(:params, :phone2Label).to_s.downcase.gsub('phone', '').strip if args.dig(:params, :phone2).present? && args.dig(:params, :phone2Label).present?
        response[:phones][args.dig(:params, :phone3).to_s.clean_phone] = args.dig(:params, :phone3Label).to_s.downcase.gsub('phone', '').strip if args.dig(:params, :phone3).present? && args.dig(:params, :phone3Label).present?
      else
        account  = self.account(args.dig(:params, :accountID).to_s)

        response = {
          id:              account.dig(:accountID).to_s,
          lastname:        account.dig(:lastName).to_s,
          firstname:       account.dig(:firstName).to_s,
          email:           account.dig(:email).to_s,
          companyname:     account.dig(:companyName).to_s,
          address_01:      account.dig(:address1).to_s,
          address_02:      account.dig(:address2).to_s,
          city:            account.dig(:city).to_s,
          state:           account.dig(:state).to_s,
          postal_code:     account.dig(:zip).to_s,
          country:         account.dig(:country).to_s,
          commercial:      account.dig(:commercial).to_bool,
          account_type:    account.dig(:accountType).to_s,
          account_subtype: account.dig(:accountSubType).to_s,
          phones:          {},
          lead_source_id:  account.dig(:leadSourceID)
        }

        response[:phones][account.dig(:fax).to_s.clean_phone] = 'fax' if account.dig(:fax).present?
        response[:phones][account.dig(:phone1).to_s.clean_phone] = account.dig(:phone1Label).to_s.downcase.gsub('phone', '').strip if account.dig(:phone1).present? && account.dig(:phone1Label).present?
        response[:phones][account.dig(:phone2).to_s.clean_phone] = account.dig(:phone2Label).to_s.downcase.gsub('phone', '').strip if account.dig(:phone2).present? && account.dig(:phone2Label).present?
        response[:phones][account.dig(:phone3).to_s.clean_phone] = account.dig(:phone3Label).to_s.downcase.gsub('phone', '').strip if account.dig(:phone3).present? && account.dig(:phone3Label).present?
      end

      response
    end

    def parse_order_from_webhook(args = {})
      response = {}

      return response unless %w[appointment order].include?(args.dig(:event_object).to_s.downcase) && (order = self.order(args.dig(:params, :orderID).to_s)).present?

      response = {
        id:                  args.dig(:params, :orderID).to_s,
        number:              order.dig(:orderNumber).to_s,
        total_amount:        order.dig(:grandTotal).to_d,
        outstanding_balance: order.dig(:balanceDue).to_d,
        status:              order.dig(:orderType).to_s.casecmp?('voided') ? 'cancelled' : 'unscheduled',
        type:                (order.dig(:orderType).to_s.casecmp?('voided') ? order.dig(:originalType) : order.dig(:orderType)).to_s.downcase, # Work Order, Estimate, Invoice, Voided
        type_voided:         order.dig(:orderType).to_s.casecmp?('voided'),
        group:               order.dig(:group).to_s,
        subgroup:            order.dig(:subGroup).to_s,
        site_id:             order.dig(:siteID).to_s,
        lead_source_id:      order.dig(:leadSourceID).to_s,
        line_items:          []
      }

      order.dig(:lineItems)&.each do |line_item|
        if line_item.dig(:itemID).present?
          response[:line_items] << {
            id:    line_item.dig(:itemID).to_s,
            name:  (line_item.dig(:name) || line_item.dig(:itemName)).to_s,
            total: line_item.dig(:total).to_d
          }
        end
      end

      response
    end

    def parse_site_from_webhook(args = {})
      case args.dig(:event_object)
      when 'order'
        site = self.site(args.dig(:params, :siteID).to_s)
      when 'appointment'
        site = self.site(args.dig(:order, :site_id).to_s)
      end

      if site.present?
        response = {
          id:          site.dig(:siteID).to_s,
          lastname:    site.dig(:lastName).to_s,
          firstname:   site.dig(:firstName).to_s,
          name:        site.dig(:name).to_s,
          email:       site.dig(:email).to_s,
          address_01:  site.dig(:address1).to_s,
          address_02:  site.dig(:address2).to_s,
          city:        site.dig(:city).to_s,
          state:       site.dig(:state).to_s,
          postal_code: site.dig(:zip).to_s,
          country:     site.dig(:country).to_s,
          phones:      {}
        }

        response[:phones][site.dig(:phone1).to_s.clean_phone] = site.dig(:phone1Label).to_s if site.dig(:phone1).present? && site.dig(:phone1Label).present?
        response[:phones][site.dig(:phone2).to_s.clean_phone] = site.dig(:phone2Label).to_s if site.dig(:phone2).present? && site.dig(:phone2Label).present?
        response[:phones][site.dig(:phone3).to_s.clean_phone] = site.dig(:phone3Label).to_s if site.dig(:phone3).present? && site.dig(:phone3Label).present?
      else
        response = {}
      end

      response
    end

    def record_api_call(error_message_prepend)
      Clients::ApiCall.create(target: 'servicemonster', client_api_id: @username, api_call: error_message_prepend)
    end

    def reset_attributes
      @error          = 0
      @faraday_result = nil
      @message        = ''
      @success        = false
    end

    # servicemonster_request(
    #   body:                  Hash,
    #   error_message_prepend: 'Integrations::ServiceMonster.xxx',
    #   method:                String,
    #   params:                Hash,
    #   default_result:        @result,
    #   url:                   String
    # )
    def servicemonster_request(args = {})
      reset_attributes
      body                  = args.dig(:body)
      error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::ServiceMonster.servicemonster_request'
      faraday_method        = (args.dig(:method) || 'get').to_s
      params                = args.dig(:params)
      @result               = args.dig(:default_result)
      url                   = args.dig(:url).to_s

      if username.blank?
        @message = 'ServiceMonster user name is required.'
        return @result
      elsif password.blank?
        @message = 'ServiceMonster password is required.'
        return @result
      elsif url.blank?
        @message = 'ServiceMonster API URL is required.'
        return @result
      end

      record_api_call(error_message_prepend)

      loop do
        redos ||= 0

        @success, @error, @message = Retryable.with_retries(
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
          @faraday_result = Faraday.send(faraday_method, url) do |req|
            req.headers['Authorization'] = "Basic #{basic_auth}"
            req.headers['Content-Type']  = 'application/json'
            req.params                   = params if params.present?
            req.body                     = body.to_json if body.present?
          end
        end

        case @faraday_result&.status
        when 200
          result   = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : @result
          @result  = if result.respond_to?(:deep_symbolize_keys)
                       result.deep_symbolize_keys
                     elsif result.respond_to?(:map)
                       result.map(&:deep_symbolize_keys)
                     else
                       result
                     end
          @success = true
        when 401

          if (redos += 1) < 5
            sleep ProcessError::Backoff.full_jitter(redos:)
            redo
          end

          @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{@faraday_result.body}"
          @success = false
        when 404
          @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{@faraday_result.body}"
          @success = false
        else

          if @faraday_result&.status == 500 && @faraday_result&.reason_phrase == 'Internal Server Error' && @faraday_result&.body.is_a?(Hash) && @faraday_result&.body&.dig(:errorMessage).to_s == 'Cannot perform runtime binding on a null reference'
            @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{@faraday_result.body}"
            @success = false
          else
            @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{@faraday_result&.body}"
            @success = false

            error = ServiceMonsterError.new(@faraday_result&.reason_phrase || 'Incomplete Faraday Request')
            error.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(error) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action(error_message_prepend)

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(args)

              Appsignal.set_tags(
                error_level: 'error',
                error_code:  0
              )
              Appsignal.add_custom_data(
                faraday_result:         @faraday_result&.to_hash,
                faraday_result_methods: @faraday_result&.public_methods.inspect,
                result:                 defined?(@result) ? @result : 'Undefined',
                file:                   __FILE__,
                line:                   __LINE__
              )
            end
          end
        end

        break
      end

      # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
      Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

      @result
    end

    def username
      @username ||= Rails.application.credentials[:servicemonster][:user_name]
    end

    def webhook_guid
      SecureRandom.uuid
    end
  end
end

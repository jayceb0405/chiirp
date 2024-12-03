# frozen_string_literal: true

# app/lib/phone_numbers/bandwidth.rb
module PhoneNumbers
  module Bandwidth
    # PhoneNumbers::Bandwidth.buy()
    #   (req) tenant:       (String)
    #   (req) client_name:  (String)
    #   (req) phone_number: (String)
    def self.buy(args = {})
      response = {
        success:         false,
        phone_number:    '',
        phone_vendor:    'bandwidth',
        phone_number_id: '',
        vendor_order_id: ''
      }

      self.subscription_create
      order = self.phone_number_order(args)

      if order[:success]
        response = {
          success:         true,
          phone_number:    order[:phone_number],
          phone_vendor:    'bandwidth',
          phone_number_id: '',
          vendor_order_id: order[:vendor_order_id]
        }
      end

      response
    end

    # PhoneNumbers::Bandwidth.destroy(client_name: String, phone_number: String)
    def self.destroy(args = {})
      response = { success: false }

      return response if args.dig(:phone_number).blank?

      response[:success], _x, _y = Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        retry_skip_reason:     'getaddrinfo: Name or service not known',
        error_message_prepend: 'PhoneNumbers::Bandwidth::PhoneNumberDelete',
        current_variables:     {
          args:        args.inspect,
          parent_file: __FILE__,
          parent_line: __LINE__
        }
      ) do
        data = {
          Name:                               "Phone Number Disconnect - #{args.dig(:client_name)}",
          DisconnectTelephoneNumberOrderType: {
            TelephoneNumberList: {
              TelephoneNumber: args.dig(:phone_number).to_s
            }
          }
        }

        result = Faraday.post("#{self.base_accounts_url}/disconnects") do |req|
          req.headers['Content-Type']  = 'application/xml'
          req.headers['Authorization'] = "Basic #{self.basic_auth}"
          req.body                     = data.to_xml(skip_instruct: true, skip_types: true, root: 'DisconnectTelephoneNumberOrder', indent: 0)
        end

        if result.success?
          data = self.process_parsed_body(ActiveSupport::XmlMini.parse(result.body))

          response = { success: true } if data.dig(:disconnect_telephone_number_order_response, :order_status).to_s.casecmp?('received')
        end
      end

      response
    end

    # find phone numbers from Bandwidth
    # PhoneNumbers::Bandwidth.find(contains: String, area_code: String, local: Boolean, toll_free: Boolean)
    #   (opt) area_code: (String / default: '')
    #   (opt) contains:  (String / default: '')

    #   (req) local:     (Boolean / default: false)
    #     ~ or ~
    #   (req) toll_free: (Boolean / default: false)
    def self.find(args = {})
      return [] unless args.dig(:local).to_bool || args.dig(:toll_free).to_bool

      find_local_phone_numbers(args) + find_toll_free_phone_numbers(args)
    end
    # local: XmlMini.parse(result.body):
    # {
    #   :search_result=>{
    #     :result_count=>50,
    #     :telephone_number_detail_list=>{
    #       :telephone_number_detail=>[
    #         {
    #           :city=>"RICHFORD",
    #           :lata=>124,
    #           :rate_center=>"RICHFORD",
    #           :state=>"VT",
    #           :full_number=>"8022556165",
    #           :tier=>0.0,
    #           :vendor_id=>49,
    #           :vendor_name=>"Bandwidth CLEC"
    #         }, ...
    #       ]
    #     }
    #   }
    # }

    # toll_free: XmlMini.parse(result.body):
    # {
    #   :search_result=>{
    #     :result_count=>10,
    #     :telephone_number_list=>{
    #       :telephone_number=>[
    #         "8443866626",
    #         "8448063866",
    #         "8556386663",
    #         "8663866141",
    #         "8668533866",
    #         "8669386607",
    #         "8776738666",
    #         "8777386631",
    #         "8887138665",
    #         "8887638660"
    #       ]
    #     }
    #   }
    # }

    # request phone number info from Bandwidth
    # PhoneNumbers::Bandwidth.lookup()
    #   (req) phone: String
    def self.lookup(args = {})
      response = {
        success:             false,
        error:               '',
        message:             '',
        national_format:     nil,
        phone_number:        nil,
        caller_name:         nil,
        caller_type:         nil,
        mobile_country_code: nil,
        mobile_network_code: nil,
        name:                nil,
        type:                nil
      }

      return response.merge(error_message: 'Phone number NOT received.') if args.dig(:phone).to_s.blank?

      begin
        result = Faraday.get("#{self.base_dashboard_api_url}/tns/#{args[:phone]}/tndetails") do |req|
          req.headers['Content-Type']  = 'application/json; charset=utf-8'
          req.headers['Authorization'] = "Basic #{self.basic_auth}"
        end

        body = ActiveSupport::XmlMini.parse(result.body).deep_symbolize_keys

        response[:success]             = true
        response[:country_code]        = nil
        response[:national_format]     = ActionController::Base.helpers.number_to_phone(args[:phone].to_s)
        response[:phone_number]        = body.dig(:TelephoneNumberResponse, :TelephoneNumberDetails, :FullNumber, :__content__).to_s
        response[:caller_name]         = nil
        response[:caller_type]         = nil
        response[:mobile_country_code] = nil
        response[:mobile_network_code] = nil
        response[:name]                = body.dig(:TelephoneNumberResponse, :TelephoneNumberDetails, :VendorName, :__content__).to_s
        response[:type]                = nil
      rescue StandardError => e
        # Something happened
        ProcessError::Report.send(
          error_message: "PhoneNumbers::TwilioNumbers::Lookup: #{e.message}",
          variables:     {
            args:        args.inspect,
            carrier:     carrier.inspect,
            e:           e.inspect,
            e_methods:   e.public_methods.inspect,
            fetch_types: (defined?(fetch_types) ? fetch_types : nil),
            phone:       args[:phone].to_s.inspect,
            phone_name:  phone_name.inspect,
            response:    (defined?(response) ? response : nil),
            result:      (defined?(result) ? result : nil),
            file:        __FILE__,
            line:        __LINE__
          }
        )
      end

      response
    end
    # {
    #   TelephoneNumberResponse: {
    #     TelephoneNumberDetails: {
    #       City:              {__content__: "BELLOWS FALLS"},
    #       Lata:              {__content__: "124"},
    #       State:             {__content__: "VT"},
    #       FullNumber:        {__content__: "8022898010"},
    #       Tier:              {__content__: "0"},
    #       VendorId:          {__content__: "49"},
    #       VendorName:        {__content__: "Bandwidth CLEC"},
    #       OnNetVendor:       {__content__: "true"},
    #       RateCenter:        {__content__: "BELLOWSFLS"},
    #       Status:            {__content__: "Inservice"},
    #       AccountId:         {__content__: "5007421"},
    #       Site:              {Id: {__content__: "46683"}, Name: {__content__: "Chiirp Development"}},
    #       SipPeer:           {
    #         PeerId:        {__content__: "649455"},
    #         PeerName:      {__content__: "Location 02"},
    #         IsDefaultPeer: {__content__: "true"}
    #       },
    #       ServiceTypes:      {ServiceType: [{__content__: "Voice"}, {__content__: "Messaging"}]},
    #       LastModified:      {__content__: "2021-03-02T20:44:27.000Z"},
    #       MessagingSettings: {
    #         SmsEnabled:      {__content__: "true"},
    #         MessageClass:    {__content__: "AGGA2P"},
    #         A2pState:        {__content__: "system_default"},
    #         AssignedNnRoute: {
    #           Nnid: {__content__: "103775"},
    #           Name: {__content__: "BW A2P - SVR - E151 (103775)"}
    #         }
    #       }
    #     }
    #   }
    # }

    # PhoneNumbers::Bandwidth.phone_number_order()
    #   (req) tenant:       (String)
    #   (req) client_name:  (String)
    #   (req) phone_number: (String)
    def self.phone_number_order(args = {})
      response = {
        success:                     false,
        vendor_order_id:             '',
        name:                        '',
        phone_vendor_sub_account_id: self.sub_account_id(args.dig(:tenant).to_s),
        phone_number:                args.dig(:phone_number).to_s,
        order_create_date:           nil
      }

      return response if args.dig(:tenant).blank? || args.dig(:client_name).blank? || args.dig(:phone_number).blank?

      response[:success], _x, _y = Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        retry_skip_reason:     'getaddrinfo: Name or service not known',
        error_message_prepend: 'PhoneNumbers::Bandwidth::PhoneNumberOrder',
        current_variables:     {
          args:        args.inspect,
          response:    response.inspect,
          parent_file: __FILE__,
          parent_line: __LINE__
        }
      ) do
        data = {
          Name:                             "Phone Number Order - #{args.dig(:client_name)}",
          SiteId:                           self.sub_account_id(args.dig(:tenant).to_s),
          Quantity:                         1,
          PartialAllowed:                   false,
          ExistingTelephoneNumberOrderType: {
            TelephoneNumberList: {
              TelephoneNumber: args.dig(:phone_number).to_s
            }
          }
        }

        result = Faraday.post("#{self.base_accounts_url}/orders") do |req|
          req.headers['Content-Type']  = 'application/xml'
          req.headers['Authorization'] = "Basic #{self.basic_auth}"
          req.body                     = data.to_xml(skip_instruct: true, skip_types: true, root: 'Order', indent: 0)
        end

        if result.success?
          data = self.process_parsed_body(ActiveSupport::XmlMini.parse(result.body))

          response = {
            success:                     true,
            vendor_order_id:             data.dig(:order_response, :order, :id).to_s,
            name:                        data.dig(:order_response, :order, :name).to_s,
            phone_vendor_sub_account_id: data.dig(:order_response, :order, :site_id).to_s,
            phone_number:                data.dig(:order_response, :order, :existing_telephone_number_order_type, :telephone_number_list, :telephone_number).to_s,
            order_create_date:           data.dig(:order_response, :order, :order_create_date).iso8601
          }
        end
      end

      response
    end
    # order response
    # {
    #   :order_response=>{
    #     :order=>{
    #       :name=>"Phone Number Order - Joe's Garage",
    #       :order_create_date=>Tue, 09 Mar 2021 01:27:57 +0000,
    #       :back_order_requested=>false,
    #       :id=>"0ae58744-abc5-4dd2-ae7d-8ed5d8cd9cd3",
    #       :existing_telephone_number_order_type=>{
    #         :telephone_number_list=>{
    #           :telephone_number=>"8024944308"
    #         }
    #       },
    #       :partial_allowed=>false,
    #       :site_id=>46683
    #     },
    #     :order_status=>"RECEIVED"
    #   }
    # }

    # PhoneNumbers::Bandwidth.status_update(String)
    def self.status_update(order_id)
      response = { success: false, completed: false, failed: false, phone_number: '' }

      if order_id.present?
        response[:success], _x, _y = Retryable.with_retries(
          rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
          retry_skip_reason:     'getaddrinfo: Name or service not known',
          error_message_prepend: 'PhoneNumbers::Bandwidth::UpdatePhoneNumberStatus',
          current_variables:     {
            order_id:    order_id.inspect,
            response:    response.inspect,
            parent_file: __FILE__,
            parent_line: __LINE__
          }
        ) do
          result = Faraday.get("#{self.base_accounts_url}/orders/#{order_id}") do |req|
            req.headers['Content-Type']  = 'application/xml'
            req.headers['Authorization'] = "Basic #{self.basic_auth}"
          end

          if result.success?
            data = process_parsed_body(ActiveSupport::XmlMini.parse(result.body))

            response = {
              success:      true,
              completed:    data.dig(:order_response, :completed_quantity).to_i.positive?,
              failed:       data.dig(:order_response, :failed_quantity).to_i.positive?,
              phone_number: data.dig(:order_response, :completed_numbers, :telephone_number, :full_number).to_s
            }
          end
        end
      end

      response
    end
    # {
    #   :order_response=>{
    #     :completed_quantity=>1,
    #     :created_by_user=>"api_access@kevinneubert.com",
    #     :failed_numbers=>{},
    #     :last_modified_date=>Tue, 09 Mar 2021 13:44:49 +0000,
    #     :order_complete_date=>Tue, 09 Mar 2021 13:44:49 +0000,
    #     :order=>{
    #       :name=>"Phone Number Order - Jimbob's Garage",
    #       :order_create_date=>Tue, 09 Mar 2021 13:44:48 +0000,
    #       :peer_id=>649455,
    #       :back_order_requested=>false,
    #       :existing_telephone_number_order_type=>{
    #         :telephone_number_list=>{
    #           :telephone_number=>"8022314320"
    #         }
    #       },
    #       :partial_allowed=>false,
    #       :site_id=>46683
    #     },
    #     :order_status=>"COMPLETE",
    #     :completed_numbers=>{
    #       :telephone_number=>{
    #         :full_number=>"8022314320"
    #       }
    #     },
    #     :summary=>"1 number ordered in (802)",
    #     :failed_quantity=>0.0
    #   }
    # }

    # PhoneNumbers::Bandwidth.subscription_callback(body: XML)
    def self.subscription_callback(args = {})
      response = { success: false, completed: false, failed: false, phone_number: '' }

      if args.dig(:body).present?
        data = process_parsed_body(ActiveSupport::XmlMini.parse(args[:body]))

        response = {
          success:         true,
          completed:       data.dig(:notification, :status).to_s.casecmp?('complete'),
          failed:          data.dig(:notification, :status).to_s.casecmp?('failed'),
          phone_number:    data.dig(:notification, :completed_telephone_numbers, :telephone_number).to_s,
          vendor_order_id: data.dig(:notification, :order_id).to_s
        }
      end

      response
    end
    # {
    #   :notification=>{
    #     :status=>"COMPLETE",
    #     :subscription_id=>"0012a731-79ae-4838-bdfd-030e199dbdfd",
    #     :message=>"Created a new number order for 1 number from RICHFORD, VT",
    #     :order_id=>"745c341a-e7be-496a-a8bc-cc4c1d960790",
    #     :order_type=>"orders",
    #     :completed_telephone_numbers=>{
    #       :telephone_number=>"8022556329"
    #     }
    #   }
    # }

    # PhoneNumbers::Bandwidth.subscription_create
    def self.subscription_create
      subscription = self.subscription_get

      subscription = nil if (subscription.nil? || subscription.dig(:callback_subscription, :expiry).to_i < 1_800) && self.subscription_destroy(subscription)

      unless subscription

        Retryable.with_retries(
          rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
          retry_skip_reason:     'getaddrinfo: Name or service not known',
          error_message_prepend: 'PhoneNumbers::Bandwidth::SubscriptionCreate',
          current_variables:     {
            parent_file: __FILE__,
            parent_line: __LINE__
          }
        ) do
          data = {
            OrderType:            'orders',
            CallbackSubscription: {
              URL:    Rails.application.routes.url_helpers.subscription_callback_twnumber_url(host: self.url_host, protocol: self.url_protocol),
              User:   self.application_id,
              Expiry: 3_153_600_000
            }
          }
          JsonLog.info 'PhoneNumbers::Bandwidth.subscription_create', { callback_subscription_url: data.dig(:CallbackSubscription, :URL) }

          result = Faraday.post("#{self.base_accounts_url}/subscriptions") do |req|
            req.headers['Content-Type']  = 'application/xml'
            req.headers['Authorization'] = "Basic #{self.basic_auth}"
            req.body                     = data.to_xml(skip_instruct: true, skip_types: true, root: 'Subscription', indent: 0)
          end

          subscription = self.subscription_get if result.success?
        end
      end

      subscription
    end

    # PhoneNumbers::Bandwidth.subscription_destroy(String)
    def self.subscription_destroy(subscription)
      response = false

      if subscription&.dig(:subscription_id)
        response, _x, _y = Retryable.with_retries(
          rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
          retry_skip_reason:     'getaddrinfo: Name or service not known',
          error_message_prepend: 'PhoneNumbers::Bandwidth::SubscriptionDestroy',
          current_variables:     {
            subscription: subscription.inspect,
            parent_file:  __FILE__,
            parent_line:  __LINE__
          }
        ) do
          result = Faraday.delete("#{self.base_accounts_url}/subscriptions/#{subscription[:subscription_id]}") do |req|
            req.headers['Content-Type']  = 'application/xml'
            req.headers['Authorization'] = "Basic #{self.basic_auth}"
          end

          response = true if result.success?
        end
      end

      response
    end

    # PhoneNumbers::Bandwidth.subscription_get
    def self.subscription_get
      response = nil

      Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        retry_skip_reason:     'getaddrinfo: Name or service not known',
        error_message_prepend: 'PhoneNumbers::Bandwidth::SubscriptionGet',
        current_variables:     {
          parent_file: __FILE__,
          parent_line: __LINE__
        }
      ) do
        result = Faraday.get("#{self.base_accounts_url}/subscriptions") do |req|
          req.headers['Content-Type']  = 'application/xml'
          req.headers['Authorization'] = "Basic #{self.basic_auth}"
        end

        if result.success?
          data = self.process_parsed_body(ActiveSupport::XmlMini.parse(result.body))
          subscriptions = [data.dig(:subscriptions_response, :subscriptions) || []].flatten

          subscriptions.each do |subscription|
            response = subscription if subscription.dig(:order_type).to_s == 'orders'
          end
        end
      end

      response
    end
    # subscriptions
    # {
    #   :subscriptions_response=>{
    #     :subscriptions=>{
    #       :subscription=>{
    #         :subscription_id=>"5f0c259d-655e-4644-8782-df68ad2ca929",
    #         :order_type=>"orders",
    #         :callback_subscription=>{
    #           :url=>"https://dev.chiirp.com/twnumbers/subscription_callback",
    #           :expiry=>"3153347163",
    #           :status=>"204 No Content - "
    #         }
    #       }
    #     }
    #   }
    # }

    def self.account_id
      Rails.application.credentials[:bandwidth][:account_id]
    end

    def self.application_id
      ENV.fetch('BANDWIDTH_MESSAGING_APPLICATION_ID', nil)
    end

    def self.base_accounts_url
      "#{self.base_dashboard_api_url}/accounts/#{self.account_id}"
    end

    def self.base_dashboard_api_url
      'https://dashboard.bandwidth.com/api'
    end

    def self.basic_auth
      Base64.urlsafe_encode64("#{self.user_name}:#{self.password}").strip
    end

    def self.password
      Rails.application.credentials[:bandwidth][:password]
    end

    # rubocop:disable Lint/DuplicateBranch
    def self.process_parsed_body(value)
      case
      when value.is_a?(Array)
        value.map { |i| self.process_parsed_body(i) }
      when value.is_a?(Hash)
        return self.process_parsed_body(value['__content__']) if value.keys.length == 1 && value['__content__']

        result = {}

        value.each do |k, val|
          key = k.casecmp?('lata') ? :lata : k.underscore.to_sym
          result[key] = self.process_parsed_body(val)
        end

        result
      when %w[true false].include?(value)
        value == 'true'
      when %r{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$}.match?(value)
        DateTime.iso8601(value)
      when %r{\A\d{9}\d?\Z}.match?(value)
        value
      when %r{\A[1-9]\d*\Z}.match?(value)
        Integer(value)
      when %r{\A[-+]?[0-9]*\.?[0-9]+\Z}.match?(value)
        Float(value)
      else
        value
      end
    end
    # rubocop:enable Lint/DuplicateBranch

    def self.put_result(result)
      Rails.logger.info "result.success?: #{result.success?.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      Rails.logger.info "result.status: #{result.status.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      Rails.logger.info "result.reason_phrase: #{result.reason_phrase.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }" if defined?(result.reason_phrase)
      Rails.logger.info "result.public_methods: #{result.public_methods.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      Rails.logger.info "result.body: #{result.body.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      Rails.logger.info "process_parsed_body(ActiveSupport::XmlMini.parse(result.body)): #{process_parsed_body(ActiveSupport::XmlMini.parse(result.body)).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      Rails.logger.info "ActiveSupport::XmlMini.parse(result.body): #{ActiveSupport::XmlMini.parse(result.body).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    end

    def self.sub_account_id(tenant)
      I18n.with_locale(tenant) { I18n.t("tenant.#{Rails.env}.bandwidth.subaccount_id") }
    end

    def self.url_host
      I18n.with_locale('chiirp') { I18n.t("tenant.#{Rails.env}.app_host") }
    end

    def self.url_protocol
      I18n.with_locale('chiirp') { I18n.t('tenant.app_protocol') }
    end

    def self.user_name
      Rails.application.credentials[:bandwidth][:user_name]
    end

    # find local phone numbers from Bandwidth
    # find_local_phone_numbers(contains: String, area_code: String, local: Boolean)
    #   (opt) area_code: (String / default: '')
    #   (opt) contains:  (String / default: '')
    #   (req) local:     (Boolean)
    def self.find_local_phone_numbers(args = {})
      response = []

      return response unless args.dig(:local).to_bool

      contains  = args.dig(:contains).to_s.tr('^0-9a-zA-Z*', '')
      area_code = args.dig(:area_code).to_s.tr('^0-9', '')

      Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        retry_skip_reason:     'getaddrinfo: Name or service not known',
        error_message_prepend: 'PhoneNumbers::Bandwidth.find_local_phone_numbers',
        current_variables:     {
          area_code:   area_code.inspect,
          args:        args.inspect,
          contains:    contains.inspect,
          parent_file: __FILE__,
          parent_line: __LINE__
        }
      ) do
        result = Faraday.get("#{self.base_accounts_url}/availableNumbers") do |req|
          req.headers['Content-Type']  = 'application/json; charset=utf-8'
          req.headers['Authorization'] = "Basic #{self.basic_auth}"
          req.params['enableTNDetail'] = 'true'
          req.params['quantity']       = args.dig(:local).to_bool && args.dig(:toll_free).to_bool ? 25 : 50
          req.params['localVanity']    = contains if contains.length >= 3 && contains.length <= 7
          req.params['areaCode']       = area_code if area_code.length == 3
        end

        if result.success?
          data = self.process_parsed_body(ActiveSupport::XmlMini.parse(result.body))

          response = [data.dig(:search_result, :telephone_number_detail_list, :telephone_number_detail) || []].flatten.map { |number| { city: number[:city], state: number[:state], phone_number: number[:full_number] } }
        end
      end

      response
    end

    # find toll free phone numbers from Bandwidth
    # find_toll_free_phone_numbers(contains: String, area_code: String, toll_free: Boolean)
    #   (opt) area_code: (String / default: '')
    #   (opt) contains:  (String / default: '')
    #   (req) toll_free: (Boolean)
    def self.find_toll_free_phone_numbers(args = {})
      response = []

      return response unless args.dig(:toll_free).to_bool

      contains  = args.dig(:contains).to_s.tr('^0-9a-zA-Z', '')
      area_code = args.dig(:area_code).to_s.tr('^0-9*', '')

      query_params = {}
      query_params[:tollFreeVanity]          = contains if contains.length >= 4 && contains.length <= 7
      query_params[:tollFreeWildCardPattern] = "#{area_code[0, 2]}*" if area_code.present? && query_params.dig(:tollFreeVanity).nil?
      query_params[:tollFreeWildCardPattern] = '8**' unless query_params.dig(:tollFreeWildCardPattern) || query_params.dig(:tollFreeVanity)

      Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        retry_skip_reason:     'getaddrinfo: Name or service not known',
        error_message_prepend: 'PhoneNumbers::Bandwidth::PhoneNumberFind',
        current_variables:     {
          area_code:    area_code.inspect,
          args:         args.inspect,
          contains:     contains.inspect,
          query_params: query_params.inspect,
          parent_file:  __FILE__,
          parent_line:  __LINE__
        }
      ) do
        result = Faraday.get("#{self.base_accounts_url}/availableNumbers") do |req|
          req.headers['Content-Type']           = 'application/json; charset=utf-8'
          req.headers['Authorization']          = "Basic #{self.basic_auth}"
          req.params['enableTNDetail']          = 'true'
          req.params['quantity']                = args.dig(:local).to_bool && args.dig(:toll_free).to_bool ? 25 : 50
          req.params['tollFreeVanity']          = query_params[:tollFreeVanity] if query_params[:tollFreeVanity].present?
          req.params['tollFreeWildCardPattern'] = query_params[:tollFreeWildCardPattern] if query_params[:tollFreeWildCardPattern].present?
        end

        if result.success?
          data = self.process_parsed_body(ActiveSupport::XmlMini.parse(result.body))

          response = [data.dig(:search_result, :telephone_number_list, :telephone_number) || []].flatten.map { |number| { city: '', state: '', phone_number: number } }
        end
      end

      response
    end
  end
end

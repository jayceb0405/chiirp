# frozen_string_literal: true

# app/lib/integrations/sales_rabbit/base.rb
module Integrations
  module SalesRabbit
    class Base
      class SalesRabbitRequestError < StandardError; end

      attr_accessor :error, :faraday_result, :message, :page_size, :result, :success

      # initialize SalesRabbit
      # sr_client = Integrations::SalesRabbit::Base.new()
      #   (req) api_key: (Hash)
      def initialize(api_key = '')
        reset_attributes
        @api_key   = api_key.to_s
        @page_size = 50
      end

      # sr_client.lead()
      #   (req) lead_id: (Integer)
      def lead(lead_id)
        reset_attributes

        if lead_id.to_i.zero?
          @message = 'SalesRabbit lead id is required.'
          return {}
        end

        self.salesrabbit_request(
          body:                  nil,
          headers:               nil,
          error_message_prepend: 'Integrations::SalesRabbit::Base.lead',
          method:                'get',
          params:                nil,
          default_result:        {},
          url:                   "#{base_url}/leads/#{lead_id}"
        )

        @result = @result.dig(:data) || {}
      end

      # sr_client.leads()
      #   (req) statuses:   (Array) lead statuses (name) to get leads for
      #   (opt) start_date: (String) get leads updated since this date
      def leads(args = {})
        reset_attributes
        start_time = args.dig(:start_time) && args[:start_time].respond_to?(:iso8601) ? args[:start_time] : nil
        leads      = []

        if statuses.blank?
          @message = 'SalesRabbit lead statuses are required.'
          return leads
        end

        [args.dig(:statuses) || ''].flatten.each do |status|
          page = 0

          loop do
            page += 1
            params = { page: }
            params[:status] = status if status.present?

            self.salesrabbit_request(
              body:                  nil,
              headers:               start_time ? { 'If-Modified-Since' => start_time.iso8601 } : {},
              error_message_prepend: 'Integrations::SalesRabbit::Base.leads',
              method:                'get',
              params:,
              default_result:        [],
              url:                   "#{self.base_url}/leads"
            )

            if @success
              leads += @result.dig(:data) || []
            else
              leads = []
              break
            end

            break unless @result.dig(:meta, :morePages)
          end
        end

        @result = leads

        @result
      end
      # {
      #   "data": [
      #     {
      #       "id": 15,
      #       "userName": "Kevin Neubert",
      #       "userId": 911705136,
      #       "firstName": "Jimmy",
      #       "lastName": "Dean",
      #       "phonePrimary": "8025551238",
      #       "phoneAlternate": "",
      #       "email": "",
      #       "street1": "",
      #       "street2": "",
      #       "city": "",
      #       "state": "",
      #       "zip": "",
      #       "country": "USA",
      #       "latitude": null,
      #       "longitude": null,
      #       "status": "Callback",
      #       "notes": null,
      #       "customFields": "{}",
      #       "businessName": "",
      #       "appointment": null,
      #       "integrationData": {},
      #       "statusModified": "2019-06-11T19:54:13+00:00",
      #       "dateCreated": "2019-06-11T19:54:12+00:00",
      #       "dateModified": "2019-06-11T19:54:46+00:00"
      #     }, ...
      #   ],
      #   "meta": {
      #     "resultsPerPage": 2000,
      #     "morePages": false,
      #     "currentPage": 1
      #   }
      # }

      # sr_client.statuses
      def statuses
        reset_attributes

        self.salesrabbit_request(
          body:                  nil,
          headers:               nil,
          error_message_prepend: 'Integrations::SalesRabbit::Base.statuses',
          method:                'get',
          params:                nil,
          default_result:        {},
          url:                   "#{base_url}/leadStatuses"
        )

        @result = @result.dig(:data) || []
      end

      # sr_client.users
      def users
        reset_attributes

        self.salesrabbit_request(
          body:                  nil,
          headers:               nil,
          error_message_prepend: 'Integrations::SalesRabbit::Base.users',
          method:                'get',
          params:                nil,
          default_result:        {},
          url:                   "#{base_url}/users"
        )

        @result = @result.dig(:data) || []
      end
      # response: (Hash)
      #   success: (Boolean)
      #   users: (Array)
      #     id:           (Integer)
      #     email:        (String)
      #     firstName:    (String)
      #     lastName:     (String)
      #     phone:        (String)
      #     role:         (String)
      #     orgId:        (String)
      #     recruiterId:  (String)
      #     department:   (String)
      #     region:       (String)
      #     office:       (String)
      #     team:         (String)
      #     active:       (Boolean)
      #     hireDate:     (String)
      #     dateCreated:  (String)
      #     dateModified: (String)
      #   error_code: (String)
      #   error_messages: (String)

      # sr_client.put_lead()
      #   (req) lead_id:   (Integer)
      #   (opt) firstname: (String)
      #   (opt) lastname:  (String)
      #   (opt) phone:     (String)
      #   (opt) email:     (String)
      def put_lead(args = {})
        reset_attributes
        @result = {}

        if args.dig(:lead_id).to_i.zero?
          @message = 'SalesRabbit lead id is required.'
          return @result
        end

        body = { data: {} }
        body[:data][:firstName]    = args[:firstname].to_s if args.include?(:firstname)
        body[:data][:lastName]     = args[:lastname].to_s if args.include?(:lastname)
        body[:data][:phonePrimary] = args[:phone].to_s if args.include?(:phone)
        body[:data][:email]        = args[:email].to_s if args.include?(:email)

        self.salesrabbit_request(
          body:,
          headers:               nil,
          error_message_prepend: 'Integrations::SalesRabbit::Base.put_lead',
          method:                'put',
          params:                nil,
          default_result:        {},
          url:                   "#{base_url}/leads/#{args[:lead_id]}"
        )

        @result
      end

      def success?
        @success
      end

      private

      def base_url
        'https://api.salesrabbit.com'
      end

      def record_api_call(error_message_prepend)
        Clients::ApiCall.create(target: 'salesrabbit', client_api_id: @api_key, api_call: error_message_prepend)
      end

      def reset_attributes
        @error          = 0
        @faraday_result = nil
        @message        = ''
        @success        = false
      end

      # self.salesrabbit_request(
      #   body:                  Hash,
      #   headers:               Hash,
      #   error_message_prepend: 'Integrations::SalesRabbit::Base.xxx',
      #   method:                String,
      #   params:                Hash,
      #   default_result:        @result,
      #   url:                   String,
      # )
      def salesrabbit_request(args = {})
        reset_attributes
        body                  = args.dig(:body)
        headers               = args.dig(:headers) || {}
        error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::SalesRabbit::Base.servicetitan_request'
        faraday_method        = (args.dig(:method) || 'get').to_s
        params                = args.dig(:params)
        @result               = args.dig(:default_result)
        url                   = args.dig(:url).to_s

        if @api_key.blank?
          @message = 'SalesRabbit api key is required.'
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
          @faraday_result = Faraday.send(faraday_method, url) do |req|
            req.headers['Authorization'] = "Bearer #{@api_key}"
            req.headers['Content-Type']  = 'application/json'

            headers.each do |k, v|
              req.headers[k] = v
            end

            req.params                   = params if params.present?
            req.body                     = body.to_json if body.present?
          end

          @faraday_result&.env&.dig('request_headers')&.delete('Authorization')
          result_body = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : nil

          case @faraday_result.status
          when 200
            @result  = if result_body.respond_to?(:deep_symbolize_keys)
                         result_body.deep_symbolize_keys
                       elsif result_body.respond_to?(:map)
                         result_body.map(&:deep_symbolize_keys)
                       else
                         result_body
                       end
            @success = !result_body.nil?
          when 400
            @error   = 400
            @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
            @success = false
          when 401
            @error   = 401
            @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
            @success = false
          when 404
            @error   = 404
            @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
            @success = false
          when 409
            @error   = 409
            @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
            @success = false
          else
            @error   = @faraday_result.status
            @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{result_body&.dig('errors', 'id')&.join(', ')}"
            @success = false

            error = SalesRabbitRequestError.new(@faraday_result&.reason_phrase)
            error.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(error) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action(error_message_prepend)

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(args)

              Appsignal.set_tags(
                error_level: 'info',
                error_code:  @faraday_result&.status
              )
              Appsignal.add_custom_data(
                faraday_result:         @faraday_result&.to_hash,
                faraday_result_methods: @faraday_result&.public_methods.inspect,
                result:                 @result,
                result_body:,
                file:                   __FILE__,
                line:                   __LINE__
              )
            end
          end
        end

        @success = false unless success
        @error   = error if error.to_i.positive?
        @message = message if message.present?

        # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
        Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

        @result
      end
    end
  end
end

# frozen_string_literal: true

# app/lib/integrations/out_reach.rb
module Integrations
  # process various API calls to Outreach
  class OutReach
    attr_accessor :error, :message, :refresh_token, :result, :success, :token
    attr_reader   :expires_at, :new_token, :new_refresh_token

    # initialize Outreach
    # outreach_client = Integrations::OutReach.new(token, refresh_token, expires_at, tenant)
    def initialize(token, refresh_token, expires_at, tenant = 'chiirp')
      reset_attributes
      @expires_at        = expires_at.to_i
      @refresh_token     = refresh_token.to_s
      @result            = nil
      @tenant            = tenant.to_s
      @token             = token.to_s
    end

    # get a call record from Outreach
    # outreach_client.call(outreach_id)
    def call(outreach_id)
      reset_attributes
      @result = {}

      return @result if @token.blank? || @refresh_token.blank? || outreach_id.blank?

      begin
        retries ||= 0

        loop do
          result = Faraday.get("#{base_url}#{api_url}/calls/#{outreach_id}") do |req|
            req.headers['Authorization']   = "Bearer #{@token}"
            req.headers['Content-Type']    = 'application/vnd.api+json'
          end

          if result.status == 200
            body     = JSON.parse(result.body).deep_symbolize_keys
            @result  = body.dig(:data)
            @success = true
            break
          elsif result.status == 401 && (retries += 1) < 3
            refresh_access_token
            break if @token.blank?
          else
            break
          end
        end
      rescue StandardError => e
        @error   = e.status_code if defined?(e.status_code)
        @message = "Outreach::Call::StandardError: #{e.message}"

        ProcessError::Report.send(
          error_code:    @error,
          error_message: @message,
          variables:     {
            e:               e.inspect,
            e_full_message:  e.full_message.inspect,
            e_methods:       e.public_methods.inspect,
            id:              id.inspect,
            outreach_result: defined?(outreach_result) ? outreach_result.inspect : 'Undefined',
            result:          @result.inspect,
            retries:         retries.inspect,
            success:         @success.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      @result
    end

    # get company info for current Outreach token
    # outreach_client.call_dispositions
    def call_dispositions
      reset_attributes
      @result = []

      return @result if @token.blank? || @refresh_token.blank?

      begin
        retries ||= 0

        loop do
          result = Faraday.get("#{base_url}#{api_url}/callDispositions") do |req|
            req.headers['Authorization']   = "Bearer #{@token}"
            req.headers['Content-Type']    = 'application/vnd.api+json'
          end

          if result.status == 200
            body     = JSON.parse(result.body).deep_symbolize_keys
            @result  = body.dig(:data)
            @success = true
            break
          elsif result.status == 401 && (retries += 1) < 3
            refresh_access_token
            break if @token.blank?
          else
            break
          end
        end
      rescue StandardError => e
        @error   = e.status_code if defined?(e.status_code)
        @message = "Outreach::CallDispositions::StandardError: #{e.message}"

        ProcessError::Report.send(
          error_code:    @error,
          error_message: @message,
          variables:     {
            e:               e.inspect,
            e_full_message:  e.full_message.inspect,
            e_methods:       e.public_methods.inspect,
            outreach_result: defined?(outreach_result) ? outreach_result.inspect : 'Undefined',
            result:          @result.inspect,
            retries:         retries.inspect,
            success:         @success.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      @result
    end

    # get company info for current Outreach token
    # outreach_client.company_info
    def company_info
      reset_attributes
      @result = []

      return @result if @token.blank? || @refresh_token.blank?

      begin
        retries ||= 0

        loop do
          result = Faraday.get("#{base_url}#{api_url}") do |req|
            req.headers['Authorization']   = "Bearer #{@token}"
            req.headers['Content-Type']    = 'application/vnd.api+json'
          end

          if result.status == 200
            body            = JSON.parse(result.body).deep_symbolize_keys
            company         = body.dig(:data, :attributes) || {}
            @result         = {
              name:             company.dig(:name).to_s,
              time_zone:        company.dig(:timeZone).to_s,
              default_currency: company.dig(:defaultCurrency).to_s
            }
            @success = true
            break
          elsif result.status == 401 && (retries += 1) < 3
            refresh_access_token
            break if @token.blank?
          else
            break
          end
        end
      rescue StandardError => e
        @error   = e.status_code if defined?(e.status_code)
        @message = "Outreach::CompanyInfo::StandardError: #{e.message}"

        ProcessError::Report.send(
          error_code:    @error,
          error_message: @message,
          variables:     {
            e:               e.inspect,
            e_full_message:  e.full_message.inspect,
            e_methods:       e.public_methods.inspect,
            outreach_result: defined?(outreach_result) ? outreach_result.inspect : 'Undefined',
            result:          @result.inspect,
            retries:         retries.inspect,
            success:         @success.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      @result
    end

    # parse an incoming Outreach webhook
    # outreach_client.parse_webhook(request.raw_post)
    def parse_webhook(secret, headers, raw_post)
      reset_attributes
      @result = {}

      if webhook_verified?(secret, headers, raw_post)
        data = JSON.parse(raw_post).deep_symbolize_keys

        case data.dig(:meta, :eventName).split('.').first
        when 'prospect'
          @result = {
            resource:    data.dig(:meta, :eventName).split('.').first,
            action:      data.dig(:meta, :eventName).split('.').last,
            outreach_id: data.dig(:data, :id).to_i
          }.merge(prospect(data.dig(:data, :id).to_i))
        when 'call'
          @result = {
            resource:            data.dig(:meta, :eventName).split('.').first,
            action:              data.dig(:meta, :eventName).split('.').last,
            outreach_id:         data.dig(:data, :id).to_i,
            call_disposition_id: data.dig(:data, :relationships, :callDisposition, :id).to_i
          }.merge(prospect(data.dig(:data, :relationships, :prospect, :id).to_i))
        end
      end

      @result
    end

    # request a Prospect from Outreach
    # outreach_client.prospect(outreach_id)
    def prospect(outreach_id = 0)
      reset_attributes
      @result = {}

      return @result if outreach_id.to_i.zero?

      begin
        retries ||= 0

        loop do
          outreach_result = Faraday.get("#{base_url}#{api_url}/prospects/#{outreach_id}") do |req|
            req.headers['Authorization']   = "Bearer #{@token}"
            req.headers['Content-Type']    = 'application/vnd.api+json'
          end

          if outreach_result.status == 200
            body            = JSON.parse(outreach_result.body).deep_symbolize_keys
            attributes      = body.dig(:data, :attributes) || {}
            @result         = {
              contact:          {
                firstname: attributes.dig(:firstName).to_s,
                lastname:  attributes.dig(:lastName).to_s,
                address1:  attributes.dig(:addressStreet).to_s,
                address2:  attributes.dig(:addressStreet2).to_s,
                city:      attributes.dig(:addressCity).to_s,
                state:     attributes.dig(:addressState).to_s,
                zipcode:   attributes.dig(:addressZip).to_s,
                birthdate: attributes.dig(:dateOfBirth).to_s,
                email:     attributes.dig(:emails).first.to_s
              },
              outreach_user_id: body.dig(:data, :relationships, :owner, :data, :id).to_i,
              phones:           {},
              tag_names:        attributes.dig(:tags)
            }
            attributes.dig(:mobilePhones).each { |p| @result[:phones][p.clean_phone] = 'mobile' }
            attributes.dig(:homePhones).each { |p| @result[:phones][p.clean_phone] = 'home' }
            attributes.dig(:otherPhones).each { |p| @result[:phones][p.clean_phone] = 'other' }
            attributes.dig(:workPhones).each { |p| @result[:phones][p.clean_phone] = 'work' }
            attributes.dig(:voipPhones).each { |p| @result[:phones][p.clean_phone] = 'work' }
            @success = true
            break
          elsif outreach_result.status == 401 && (retries += 1) < 3
            refresh_access_token
            @result = {}
            break if @token.blank?
          else
            break
          end
        end
      rescue StandardError => e
        @error   = e.status_code if defined?(e.status_code)
        @message = "Outreach::CompanyInfo::StandardError: #{e.message}"

        ProcessError::Report.send(
          error_code:    @error,
          error_message: @message,
          variables:     {
            e:               e.inspect,
            e_full_message:  e.full_message.inspect,
            e_methods:       e.public_methods.inspect,
            outreach_result: defined?(outreach_result) ? outreach_result.inspect : 'Undefined',
            result:          @result.inspect,
            retries:         retries.inspect,
            success:         @success.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      @result
    end

    # update Prospect in Outreach
    # outreach_client.prospect_update(contact, phones)
    def prospect_update(contact)
      reset_attributes
      @result = false

      begin
        retries ||= 0

        loop do
          data = { data: {
            type:       'prospect',
            id:         contact.dig(:outreach_id).to_i,
            attributes: {
              firstName:      contact.dig(:firstname).to_s,
              lastName:       contact.dig(:lastname).to_s,
              addressStreet:  contact.dig(:address1).to_s,
              addressStreet2: contact.dig(:address2).to_s,
              addressCity:    contact.dig(:city).to_s,
              addressState:   contact.dig(:state).to_s,
              addressZip:     contact.dig(:zipcode).to_s,
              dateOfBirth:    contact.dig(:birthdate).to_s,
              emails:         [contact.dig(:email).to_s],
              mobilePhones:   contact.dig(:mobile_phones),
              homePhones:     contact.dig(:home_phones),
              workPhones:     contact.dig(:work_phones)
            }
          } }

          outreach_result = if contact.dig(:outreach_id).to_i.positive?
                              Faraday.patch("#{base_url}#{api_url}/prospects/#{contact.dig(:outreach_id).to_i}") do |req|
                                req.headers['Authorization']   = "Bearer #{@token}"
                                req.headers['Content-Type']    = 'application/vnd.api+json'
                                req.body                       = data.to_json
                              end
                            else
                              Faraday.post("#{base_url}#{api_url}/prospects") do |req|
                                req.headers['Authorization']   = "Bearer #{@token}"
                                req.headers['Content-Type']    = 'application/vnd.api+json'
                                req.body                       = data.to_json
                              end
                            end

          if outreach_result.status == 200
            @success = true
            @result  = true
            break
          elsif outreach_result.status == 401 && (retries += 1) < 3
            refresh_access_token
            break if @token.blank?
          else
            break
          end
        end
      rescue StandardError => e
        @error   = e.status_code if defined?(e.status_code)
        @message = "Outreach::CompanyInfo::StandardError: #{e.message}"

        ProcessError::Report.send(
          error_code:    @error,
          error_message: @message,
          variables:     {
            e:               e.inspect,
            e_full_message:  e.full_message.inspect,
            e_methods:       e.public_methods.inspect,
            outreach_result: defined?(outreach_result) ? outreach_result.inspect : 'Undefined',
            result:          @result.inspect,
            retries:         retries.inspect,
            success:         @success.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      @result
    end

    def success?
      @success
    end

    # get user info for current Outreach token
    # outreach_client.company_info
    def user_info
      reset_attributes
      @result = []

      return @result if @token.blank? || @refresh_token.blank?

      begin
        retries ||= 0

        loop do
          result = Faraday.get("#{base_url}#{api_url}") do |req|
            req.headers['Authorization']   = "Bearer #{@token}"
            req.headers['Content-Type']    = 'application/vnd.api+json'
          end

          if result.status == 200
            body            = JSON.parse(result.body).deep_symbolize_keys
            user            = body.dig(:meta, :user) || {}
            @result         = {
              firstname: user.dig(:firstName).to_s,
              lastname:  user.dig(:lastName).to_s,
              email:     user.dig(:email).to_s,
              id:        user.dig(:id).to_i
            }
            @success = true
            break
          elsif result.status == 401 && (retries += 1) < 3
            refresh_access_token
            break if @token.blank?
          else
            break
          end
        end
      rescue StandardError => e
        @error   = e.status_code if defined?(e.status_code)
        @message = "Outreach::CompanyInfo::StandardError: #{e.message}"

        ProcessError::Report.send(
          error_code:    @error,
          error_message: @message,
          variables:     {
            e:               e.inspect,
            e_full_message:  e.full_message.inspect,
            e_methods:       e.public_methods.inspect,
            outreach_result: defined?(outreach_result) ? outreach_result.inspect : 'Undefined',
            result:          @result.inspect,
            retries:         retries.inspect,
            success:         @success.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      @result
    end

    # collect all Users from Outreach
    # outreach_client.users
    def users
      reset_attributes
      @result = []

      return @result if @token.blank? || @refresh_token.blank?

      begin
        url       = "#{base_url}#{api_url}/users"
        retries ||= 0

        loop do
          result = Faraday.get(url) do |req|
            req.headers['Authorization']   = "Bearer #{@token}"
            req.headers['Content-Type']    = 'application/vnd.api+json'

            if url == "#{base_url}#{api_url}/users"
              req.params['page[size]']       = 50
              req.params['count']            = false
              req.params['filter[locked]']   = false
            end
          end

          if result.status == 200
            body     = JSON.parse(result.body).deep_symbolize_keys
            @result += body.dig(:data)

            if body.dig(:links, :next).to_s.present?
              url = body.dig(:links, :next).to_s
            else
              @success = true
              break
            end
          elsif result.status == 401 && (retries += 1) < 3
            refresh_access_token
            break if @token.blank?
          else
            break
          end
        end
      rescue StandardError => e
        @error   = e.status_code if defined?(e.status_code)
        @message = "Outreach::Users::StandardError: #{e.message}"

        ProcessError::Report.send(
          error_code:    @error,
          error_message: @message,
          variables:     {
            e:               e.inspect,
            e_full_message:  e.full_message.inspect,
            e_methods:       e.public_methods.inspect,
            outreach_result: defined?(outreach_result) ? outreach_result.inspect : 'Undefined',
            result:          @result.inspect,
            retries:         retries.inspect,
            success:         @success.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      @result
    end

    # validate (refresh if needed) a token/refresh token
    # outreach_client.validate_token
    def validate_token
      @new_token         = nil
      @new_refresh_token = nil

      refresh_access_token if @expires_at < 10.minutes.ago.to_i
    end

    # verify a webhhok payload with it's secret
    # outreach_client.webhook_verified?(secret, headers, body)
    def webhook_verified?(secret, headers, body)
      headers['Outreach-Webhook-Signature'] == webhook_signature(secret, body)
    end

    # subscribe to a Outreach webhook
    # outreach_client.webhook_subscribe(client_id, resource, action, api_key)
    # resource: "*", "prospect", "sequenceState", etc...
    # actions: "*", "created", "updated", "destroyed"
    def webhook_subscribe(client_id, resource, action, api_key)
      tenant_app_host     = I18n.t("tenant.#{Rails.env}.app_host", locale: @tenant)
      tenant_app_protocol = I18n.t('tenant.app_protocol')
      reset_attributes
      @result = {}

      return @result if @token.blank? || @refresh_token.blank? || resource.blank? || action.blank? || api_key.blank?

      begin
        retries ||= 0

        loop do
          result = Faraday.post("#{base_url}#{api_url}/webhooks") do |req|
            req.headers['Authorization']   = "Bearer #{@token}"
            req.headers['Content-Type']    = 'application/vnd.api+json'
            req.body = { data: {
              type:       'webhook',
              attributes: {
                resource:,
                action:,
                secret:   api_key,
                url:      Rails.application.routes.url_helpers.integrations_outreach_url(client_id.to_i, host: tenant_app_host, protocol: tenant_app_protocol)
              }
            } }.to_json
          end

          if result.status == 201
            body            = JSON.parse(result.body).deep_symbolize_keys
            @result         = (body.dig(:data, :attributes) || {}).merge({ id: body.dig(:data, :id).to_i })
            @success        = true
            break
          elsif result.status == 401 && (retries += 1) < 3
            refresh_access_token
            break if @token.blank?
          else
            break
          end
        end
      rescue StandardError => e
        @error   = e.status_code if defined?(e.status_code)
        @message = "Outreach::WebhookSubscribe::StandardError: #{e.message}"

        ProcessError::Report.send(
          error_code:    @error,
          error_message: @message,
          variables:     {
            e:               e.inspect,
            e_full_message:  e.full_message.inspect,
            e_methods:       e.public_methods.inspect,
            outreach_result: defined?(outreach_result) ? outreach_result.inspect : 'Undefined',
            result:          @result.inspect,
            retries:         retries.inspect,
            success:         @success.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      @result
    end

    # unsubscribe from a Outreach webhook
    # outreach_client.webhook_unsubscribe(id)
    def webhook_unsubscribe(id = 0)
      reset_attributes
      @result = false

      return @result if @token.blank? || @refresh_token.blank? || id.to_i.zero?

      begin
        retries ||= 0

        loop do
          result = Faraday.delete("#{base_url}#{api_url}/webhooks/#{id.to_i}") do |req|
            req.headers['Authorization']   = "Bearer #{@token}"
            req.headers['Content-Type']    = 'application/vnd.api+json'
          end

          if result.status == 204
            @result  = true
            @success = true
            break
          elsif result.status == 401 && (retries += 1) < 3
            refresh_access_token
            break if @token.blank?
          else
            break
          end
        end
      rescue StandardError => e
        @error   = e.status_code if defined?(e.status_code)
        @message = "Outreach::WebhookSubscribe::StandardError: #{e.message}"

        ProcessError::Report.send(
          error_code:    @error,
          error_message: @message,
          variables:     {
            e:               e.inspect,
            e_full_message:  e.full_message.inspect,
            e_methods:       e.public_methods.inspect,
            outreach_result: defined?(outreach_result) ? outreach_result.inspect : 'Undefined',
            result:          @result.inspect,
            retries:         retries.inspect,
            success:         @success.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      @result
    end

    # return a list of existing webhooks for User
    # outreach_client.webhooks
    def webhooks
      reset_attributes
      @result = []

      return @result if @token.blank? || @refresh_token.blank?

      begin
        retries ||= 0

        loop do
          result = Faraday.get("#{base_url}#{api_url}/webhooks") do |req|
            req.headers['Authorization']   = "Bearer #{@token}"
            req.headers['Content-Type']    = 'application/vnd.api+json'
          end

          if result.status == 200
            body     = JSON.parse(result.body).deep_symbolize_keys
            @result  = body.dig(:data).map { |webhook| { id: webhook.dig(:id).to_i }.merge(webhook.dig(:attributes)) }
            @success = true
            break
          elsif result.status == 401 && (retries += 1) < 3
            refresh_access_token
            break if @token.blank?
          else
            break
          end
        end
      rescue StandardError => e
        @error   = e.status_code if defined?(e.status_code)
        @message = "Outreach::Webhooks::StandardError: #{e.message}"

        ProcessError::Report.send(
          error_code:    @error,
          error_message: @message,
          variables:     {
            e:               e.inspect,
            e_full_message:  e.full_message.inspect,
            e_methods:       e.public_methods.inspect,
            outreach_result: defined?(outreach_result) ? outreach_result.inspect : 'Undefined',
            result:          @result.inspect,
            retries:         retries.inspect,
            success:         @success.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      @result
    end

    private

    def api_url
      '/api/v2'
    end

    def base_url
      'https://api.outreach.io'
    end

    def refresh_access_token
      tenant_app_host     = I18n.t("tenant.#{Rails.env}.app_host", locale: @tenant)
      tenant_app_protocol = I18n.t('tenant.app_protocol')
      response            = false

      Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        error_message_prepend: 'Outreach::RefreshAccessToken',
        current_variables:     {
          parent_file:         __FILE__,
          parent_line:         __LINE__,
          tenant_app_host:     tenant_app_host.inspect,
          tenant_app_protocol: tenant_app_protocol.inspect
        }
      ) do
        result = Faraday.post("#{base_url}/oauth/token") do |req|
          req.params[:client_id]     = Rails.application.credentials[:outreach][@tenant.to_sym][:app_id]
          req.params[:client_secret] = Rails.application.credentials[:outreach][@tenant.to_sym][:secret]
          req.params[:redirect_uri]  = Rails.application.routes.url_helpers.send(:"user_outreach_#{@tenant}_omniauth_authorize_url", host: tenant_app_host, protocol: tenant_app_protocol)
          req.params[:grant_type]    = 'refresh_token'
          req.params[:refresh_token] = @refresh_token
        end

        if result.status == 200
          result_body        = JSON.parse(result.body).symbolize_keys
          @token             = result_body.dig(:access_token).to_s
          @refresh_token     = result_body.dig(:refresh_token).to_s
          @expires_at        = (Time.current + result_body.dig(:expires_in).to_i.seconds).to_i
          @new_token         = @token
          @new_refresh_token = @refresh_token
          response           = true
        end
      end

      response
    end

    def reset_attributes
      @error             = 0
      @message           = ''
      @new_token         = nil
      @new_refresh_token = nil
      @success           = false
    end

    def webhook_signature(secret, body)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, body)
    end
  end
end

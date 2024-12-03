# frozen_string_literal: true

# https://docs.sendgrid.com/for-developers/sending-email/automating-subusers
# https://docs.sendgrid.com/api-reference/subusers-api/list-all-subusers
# app/lib/integrations/e_mail/v1/base.rb
# Integrations::EMail::V1::Base.new(username, api_key, client_id)
module Integrations
  module EMail
    module V1
      class Base
        class SendGridRequestError < StandardError; end

        delegate :url_helpers, to: 'Rails.application.routes'

        attr_accessor :api_key, :client_id, :error, :faraday_result, :message, :result, :success, :tenant, :username
        alias success? success

        BASE_URL = 'https://api.sendgrid.com/v3'

        def initialize(username, api_key, client_id, tenant: 'chiirp')
          self.api_key   = api_key
          self.client_id = client_id
          self.tenant    = tenant
          self.username  = username

          reset_attributes
        end

        def create_subaccount(email, password, ips)
          sendgrid_request(
            url:                   'subusers',
            body:                  {
              username:,
              email:,
              password:,
              ips:
            },
            default_result:        {},
            error_message_prepend: 'Integrations::EMail::V1::Base.create_subaccount',
            method:                'post',
            params:                nil,
            subaccount:            nil
          )
        end
        # example:
        # {
        #   :username=>"sg-chiirp-client-1",
        #   :user_id=>37015210,
        #   :email=>"support+sg-chiirp-client-1@chiirp.com",
        #   :credit_allocation=>{:type=>"unlimited"}
        # }

        def create_api_keys(name, scopes)
          sendgrid_request(
            url:                   'api_keys',
            body:                  {
              name:,
              scopes:
            },
            default_result:        {},
            error_message_prepend: 'Integrations::EMail::V1::Base.create_api_keys',
            method:                'post',
            params:                nil,
            subaccount:            username
          )
        end
        # example:
        # {
        #   :api_key=>"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",
        #   :api_key_id=>"3dh3pUHpTz-Tp1yh2LOF_Q",
        #   :name=>"sg-chiirp-client-1",
        #   :scopes=>["mail.send"]
        # }

        def create_domain(domain)
          # https://docs.sendgrid.com/api-reference/domain-authentication/authenticate-a-domain
          sendgrid_request(
            url:                   'whitelabel/domains',
            body:                  {
              automatic_security:   true,
              # build a 3 char string of random lower case letters and numbers
              custom_dkim_selector: Array.new(3) { (('a'..'z').to_a + (0..9).to_a).sample }.join,
              default:              false,
              domain:,
              username:
            },
            default_result:        {},
            error_message_prepend: 'Integrations::EMail::V1::Base.create_domain',
            method:                'post',
            params:                nil,
            subaccount:            nil
          )
        end
        # example:
        # {
        #   :id=>18644612,
        #   :user_id=>37015210,
        #   :subdomain=>"em9757",
        #   :domain=>"kevinneubert.com",
        #   :username=>"sg-chiirp-client-1",
        #   :ips=>[],
        #   :custom_spf=>false,
        #   :default=>false,
        #   :legacy=>false,
        #   :automatic_security=>true,
        #   :valid=>false,
        #   :dns=>{
        #     :mail_cname=>{
        #       :valid=>false,
        #       :type=>"cname",
        #       :host=>"em9757.kevinneubert.com",
        #       :data=>"u37015210.wl211.sendgrid.net"
        #     },
        #     :dkim1=>{
        #       :valid=>false,
        #       :type=>"cname",
        #       :host=>"s1._domainkey.kevinneubert.com",
        #       :data=>"s1.domainkey.u37015210.wl211.sendgrid.net"
        #     },
        #     :dkim2=>{
        #       :valid=>false,
        #       :type=>"cname",
        #       :host=>"s2._domainkey.kevinneubert.com",
        #       :data=>"s2.domainkey.u37015210.wl211.sendgrid.net"
        #     }
        #   }
        # }

        def delete_account
          sendgrid_request(
            url:                   "subusers/#{username}",
            body:                  nil,
            default_result:        '',
            error_message_prepend: 'Integrations::EMail::V1::Base.delete_account',
            method:                'delete',
            params:                nil,
            subaccount:            nil
          )
        end
        # example:
        # ''

        def reputation
          if username.present?
            # https://docs.sendgrid.com/api-reference/subusers-api/retrieve-subuser-reputations
            sendgrid_request(
              url:                   'subusers/reputations',
              body:                  nil,
              default_result:        '',
              error_message_prepend: 'Integrations::EMail::V1::Base.reputation',
              method:                'get',
              params:                { usernames: username },
              subaccount:            nil
            )&.first&.dig(:reputation).to_i
          else
            0
          end
        end

        def stats(aggregated_by: 'month', start_date: 30.days.ago.to_date)
          # https://docs.sendgrid.com/api-reference/subuser-statistics/retrieve-email-statistics-for-your-subuser
          sendgrid_request(
            url:                   'subusers/stats',
            body:                  nil,
            default_result:        '',
            error_message_prepend: 'Integrations::EMail::V1::Base.stats',
            method:                'get',
            params:                { subusers: username, start_date:, aggregated_by: },
            subaccount:            nil
          )
        end

        def verify_domain(id)
          sendgrid_request(
            url:                   "whitelabel/domains/#{id}/validate",
            body:                  nil,
            default_result:        {},
            error_message_prepend: 'Integrations::EMail::V1::Base.verify_domain',
            method:                'post',
            params:                nil,
            subaccount:            nil
          )
        end
        # example:
        # {
        #   :id=>18644696,
        #   :valid=>false,
        #   :validation_results=>{
        #     :mail_cname=>{
        #       :valid=>false,
        #       :reason=>"Expected CNAME for \"em8924.kevinneubert.com\" to match \"u37015443.wl194.sendgrid.net\"."
        #     },
        #     :dkim1=>{
        #       :valid=>false,
        #       :reason=>"Expected CNAME for \"s1._domainkey.kevinneubert.com\" to match \"s1.domainkey.u37015443.wl194.sendgrid.net\"."
        #     },
        #     :dkim2=>{
        #       :valid=>false,
        #       :reason=>"Expected CNAME for \"s2._domainkey.kevinneubert.com\" to match \"s2.domainkey.u37015443.wl194.sendgrid.net\"."
        #     }
        #   }
        # }

        # send an email through SendGrid
        # email_client.send_email()
        #   (req) from_email:  (Hash)    ex: { email: '', name: ''}
        #   (req) to_email:    (Array)   ex: [{ email: '', name: ''}]
        #   (req) subject:     (String)
        #   (req) content:     (String)
        #   (opt) cc_email:    (Array)   ex: [{ email: '', name: ''}]
        #   (opt) bcc_email:   (Array)   ex: [{ email: '', name: ''}]
        #   (opt) reply_email: (Hash)    ex: { email: '', name: ''}
        #   (opt) contact_id:  (Integer)
        def send_email(args = {})
          reset_attributes
          from_email  = args.dig(:from_email).is_a?(Hash) ? args[:from_email] : {}
          to_email    = args.dig(:to_email).is_a?(Array) ? args[:to_email] : []

          if api_key.blank? || client_id.zero? || tenant.blank?
            @error = 'API Key is required.'
            return @result
          elsif @client_id.zero?
            @error = 'Client id is required.'
            return @result
          elsif @tenant.blank?
            @error = 'Tenant is required.'
            return @result
          elsif to_email.each { |m| to_email.delete(m) if m.dig(:email).blank? }.blank?
            @error = '"To" email address is required.'
            return @result
          elsif from_email.blank? || from_email.dig(:email).blank?
            @error = '"From" email address is required.'
            return @result
          elsif args.dig(:subject).blank?
            @error = 'Email subject is required.'
            return @result
          elsif args.dig(:content).blank?
            @error = 'Email content is required.'
            return @result
          end

          tenant_app_host     = I18n.with_locale(@tenant) { I18n.t("tenant.#{Rails.env}.app_host") }
          tenant_app_protocol = I18n.with_locale(@tenant) { I18n.t('tenant.app_protocol') }

          # add unsubscribe to email content
          content  = args[:content]
          content += "<p style=\"font-size:small;-webkit-text-size-adjust:none;color:#666;\">&mdash;<br />Reply to this email directly or #{ActionController::Base.helpers.link_to 'unsubscribe', url_helpers.welcome_unsubscribe_url(@client_id, args[:contact_id].to_i, host: tenant_app_host, protocol: tenant_app_protocol)}.</p>" unless @client_id.zero? || args.dig(:contact_id).to_i.zero?
          #
          # You are receiving this because you were assigned.
          # Reply to this email directly, view it on GitHub, or unsubscribe.

          # create post body
          body = { personalizations: [{}] }
          body[:personalizations][0][:to]  = to_email
          body[:personalizations][0][:cc]  = args[:cc_email] if args.dig(:cc_email).present?
          body[:personalizations][0][:bcc] = args[:bcc_email] if args.dig(:bcc_email).present?
          body[:from]                      = from_email
          body[:reply_to]                  = args[:reply_email] if args.dig(:reply_email).present?
          body[:subject]                   = args[:subject].to_s
          # rubocop:disable Rails/OutputSafety
          body[:content]                   = [{ type: 'text/html', value: content.html_safe }]
          # rubocop:enable Rails/OutputSafety
          body[:attachments]               = args[:attachments] if args.dig(:attachments).is_a?(Array) && args[:attachments].present?

          @result = begin
            sendgrid_request(
              url:                   'mail/send',
              body:,
              default_result:        false,
              error_message_prepend: 'Integrations::EMail::V1::Base.send_email',
              method:                'post',
              params:                nil,
              subaccount:            nil
            )
          rescue StandardError => e
            @message = "SendGrid: #{e.message}"
            @success = false

            ProcessError::Report.send(
              error_code:    @error,
              error_message: "Integrations::SendGrid::V1::Base.send_email: #{e.message}",
              variables:     {
                e:              e.inspect,
                e_message:      e.message,
                finished:       @faraday_result.finished?.inspect,
                reason_phrase:  @faraday_result.reason_phrase.inspect,
                result_methods: @faraday_result.public_methods.inspect,
                status:         @faraday_result.status.inspect,
                success:        @faraday_result.success?.inspect,
                api_key:        @api_key.inspect,
                args:           args.inspect,
                client_id:      @client_id.inspect,
                body:           body.inspect,
                from_email:     from_email.inspect,
                result:         result.inspect,
                tenant:         @tenant.inspect,
                to_email:       to_email.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )

            false
          end

          JsonLog.info 'Integrations::EMail::V1::Base.send_email', { success: @success, error_message: @message, error_code: @error, result: @result, faraday_result: @faraday_result }

          @result
        end

        # get a list of SendGrid subaccounts
        # Integrations::Email::V1::Base.new().subaccounts
        # em_client.subaccounts
        def subaccounts
          sendgrid_request(
            url:                   'subusers',
            body:                  nil,
            default_result:        [],
            error_message_prepend: 'Integrations::EMail::V1::Base.subaccounts',
            method:                'get',
            params:                nil,
            subaccount:            nil
          )
        end

        # sendgrid_request(
        #   (req) url:                   String,
        #   (opt) body:                  Hash,
        #   (opt) default_result:        String/Array/Hash/Boolean,
        #   (opt) error_message_prepend: 'Integrations::EMail::V1::Base.xxx',
        #   (opt) method:                String,
        #   (opt) params:                Hash,
        #   (opt) subaccount:            String
        # )
        def sendgrid_request(args = {})
          reset_attributes
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::EMail::V1::Base'
          @result               = args.dig(:default_result)

          raise ArgumentError, 'SendGrid API URL is required.' if args.dig(:url).to_s.blank?

          record_api_call(error_message_prepend)

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
            @faraday_result = Faraday.send((args.dig(:method) || 'get').to_s, "#{BASE_URL}/#{args[:url]}") do |req|
              req.headers['Authorization']            = "Bearer #{api_key}"
              req.headers['Content-Type']             = 'application/json'
              req.headers['Accept']                   = 'application/json'
              req.headers['On-Behalf-Of']             = args[:subaccount] if args.dig(:subaccount).present?
              req.params                              = args[:params] if args.dig(:params).present?
              req.body                                = args[:body].to_json if args.dig(:body).present?
            end
          end

          result_body = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : args.dig(:default_result)

          case @faraday_result&.status
          when 200, 201, 202, 204
            @result = if result_body.respond_to?(:deep_symbolize_keys)
                        result_body.deep_symbolize_keys
                      elsif result_body.respond_to?(:map)
                        result_body.map(&:deep_symbolize_keys)
                      else
                        result_body
                      end

            if @result.is_a?(Hash)
              case @result.dig(:Code).to_i
              when 404, 405, 411, 412, 500
                @message = @result.dig(:Message).to_s
                @result  = {}
                @success = false
              end
            end
          when 401, 404
            @error   = @faraday_result&.status
            @message = @faraday_result&.reason_phrase
            @result  = {}
            @success = false
          else
            @error   = @faraday_result&.status
            @message = @faraday_result&.reason_phrase
            @result  = {}
            @success = false

            error = SendGridRequestError.new(@message)
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
                faraday_result:         @faraday_result&.inspect,
                faraday_result_methods: @faraday_result&.methods.inspect,
                reason_phrase:          @faraday_result&.reason_phrase.inspect,
                result:                 @result.inspect,
                status:                 @faraday_result&.status.inspect,
                file:                   __FILE__,
                line:                   __LINE__
              )
            end
          end

          # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
          Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

          @result
        end

        def record_api_call(error_message_prepend)
          Clients::ApiCall.create(target: 'sendgrid', client_api_id: api_key, api_call: error_message_prepend)
        end

        def reset_attributes
          @error = 0
          @faraday_result = nil
          @message        = ''
          @success        = false
          @result         = {}
        end

        def valid_credentials?
          username.present? && api_key.present?
        end
      end
    end
  end
end

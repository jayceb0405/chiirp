# frozen_string_literal: true

# app/lib/integrations/send_grid/v1/base.rb
module Integrations
  module SendGrid
    module V1
      class Base
        class SendGridSendEmailError < StandardError; end

        delegate :url_helpers, to: 'Rails.application.routes'

        attr_reader :api_key, :client_id, :error, :faraday_result, :message, :result, :tenant, :success
        alias success? success

        # sg_client = Integrations::SendGrid::V1::Base.new()
        #   (req) api_key:   (String)
        #   (req) client_id: (Integer)
        #   (req) tenant:    (String)
        def initialize(args = {})
          reset_attributes
          @api_key   = args.dig(:api_key).to_s
          @client_id = args.dig(:client_id).to_i
          @tenant    = args.dig(:tenant).to_s
        end

        # sg_client.parse_email()
        def parse_email(args = {})
          reset_attributes

          @result = {
            attachment_info: args.dig(:attachments).to_i.positive? ? args.dig(:attachment_info) || {} : {},
            attachments:     args.dig(:attachments).to_i,
            bcc:             args.dig(:envelope, :bcc) || [],
            cc:              args.dig(:envelope, :cc) || [],
            dkim:            args.dig(:dkim).to_s,
            envelope:        args.dig(:envelope),
            from:            args.dig(:envelope, :from).to_s,
            headers:         args.dig(:headers).to_s,
            html_body:       args.dig(:html).to_s,
            spam_report:     args.dig(:spam_report).to_s,
            spam_score:      args.dig(:spam_score).to_i,
            subject:         args.dig(:subject).to_s,
            text_body:       args.dig(:text).to_s,
            to:              args.dig(:envelope, :to) || []
          }

          addresses = parse_email_addresses_from_headers(args.dig(:headers).to_s)
          @result[:from] = addresses[:from]&.first || { email: args.dig(:from), name: nil }
          @result[:cc]   = addresses[:cc] || []

          # get to address from envelope
          @result[:to] = args.dig(:envelope, :to).any? ? [{ name: nil, email: args.dig(:envelope, :to).first }] : []

          @success = (@result[:from]&.length.to_i + @result[:to]&.length.to_i + @result[:cc]&.length.to_i).positive?

          # Rails.logger.info "params.dig(:headers): #{params.dig(:headers).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          # Rails.logger.info "params.dig(:subject): #{params.dig(:subject).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          # Rails.logger.info "params.dig(:text): #{params.dig(:text).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          # Rails.logger.info "params.dig(:to): #{params.dig(:to).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          # Rails.logger.info "params.dig(:from): #{params.dig(:from).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          # Rails.logger.info "params.dig(:html): #{params.dig(:html).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          # Rails.logger.info "params.dig(:envelope): #{JSON.parse(params.dig(:envelope)).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          # Rails.logger.info "params.dig(:envelope.to): #{JSON.parse(params.dig(:envelope))['to'].inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          # Rails.logger.info "params.dig(:envelope.from): #{JSON.parse(params.dig(:envelope))['from'].inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          # Rails.logger.info "params.dig(:'content-ids'): #{params.dig(:'content-ids').inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          # Rails.logger.info "params.dig(:attachments): #{params.dig(:attachments).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          # Rails.logger.info "params.dig(:attachment-info): #{JSON.parse(params.dig(:'attachment-info')).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

          @result
        end

        # send an email through SendGrid
        # sg_client.send_email()
        #   (req) from_email: (Hash)
        #           { email: '', name: ''}
        #   (req) to_email:   (Array)
        #           [{ email: '', name: ''}]
        #   (req) subject:    (String)
        #   (req) content:    (String)
        #   (opt) cc_email:    (Array)
        #           [{ email: '', name: ''}]
        #   (opt) bcc_email:   (Array)
        #           [{ email: '', name: ''}]
        #   (opt) reply_email: (Hash)
        #           { email: '', name: ''}
        #   (opt) contact_id:  (Integer)
        def send_email(args = {})
          reset_attributes
          from_email  = args.dig(:from_email).is_a?(Hash) ? args[:from_email] : {}
          to_email    = args.dig(:to_email).is_a?(Array) ? args[:to_email] : []
          cc_email    = args.dig(:cc_email)
          bcc_email   = args.dig(:bcc_email)
          contact_id  = args.dig(:contact_id).to_i
          attachments = args.dig(:attachments)

          if @api_key.blank? || @client_id.zero? || @tenant.blank?
            @message = 'API Key is required.'
            return @result
          elsif @client_id.zero?
            @message = 'Client id is required.'
            return @result
          elsif @tenant.blank?
            @message = 'Tenant is required.'
            return @result
          elsif to_email.each { |m| to_email.delete(m) if m.dig(:email).blank? }.blank?
            @message = '"To" email address is required.'
            return @result
          elsif from_email.blank? || from_email.dig(:email).blank?
            @message = '"From" email address is required.'
            return @result
          elsif args.dig(:subject).blank?
            @message = 'Email subject is required.'
            return @result
          elsif args.dig(:content).blank?
            @message = 'Email content is required.'
            return @result
          end

          tenant_app_host     = I18n.with_locale(@tenant) { I18n.t("tenant.#{Rails.env}.app_host") }
          tenant_app_protocol = I18n.with_locale(@tenant) { I18n.t('tenant.app_protocol') }

          # add unsubscribe to email content
          content  = args[:content]
          content += "<p style=\"font-size:small;-webkit-text-size-adjust:none;color:#666;\">&mdash;<br />Reply to this email directly or #{ActionController::Base.helpers.link_to 'unsubscribe', url_helpers.welcome_unsubscribe_url(@client_id, contact_id, host: tenant_app_host, protocol: tenant_app_protocol)}.</p>" unless @client_id.zero? || contact_id.zero?
          #
          # You are receiving this because you were assigned.
          # Reply to this email directly, view it on GitHub, or unsubscribe.

          # create post body
          data = { personalizations: [{}] }
          data[:personalizations][0][:to]  = to_email
          data[:personalizations][0][:cc]  = cc_email if cc_email.present?
          data[:personalizations][0][:bcc] = bcc_email if bcc_email.present?
          data[:from]             = from_email
          data[:reply_to]         = args[:reply_email] if args.dig(:reply_email).present?
          data[:subject]          = args[:subject].to_s
          # rubocop:disable Rails/OutputSafety
          data[:content]          = [{ type: 'text/html', value: content.html_safe }]
          # rubocop:enable Rails/OutputSafety
          data[:attachments]      = attachments if attachments.is_a?(Array) && attachments.present?

          begin
            @faraday_result = Faraday.post("#{base_url}v3/mail/send") do |req|
              req.headers['Authorization'] = "Bearer #{@api_key}"
              req.headers['Content-Type']  = 'application/json'
              req.body = data.to_json
            end

            result_body = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : nil

            case @faraday_result&.status
            when 200, 202
              @result  = if result_body.respond_to?(:deep_symbolize_keys)
                           result_body.deep_symbolize_keys
                         elsif result_body.respond_to?(:map)
                           result_body.map(&:deep_symbolize_keys)
                         else
                           result_body
                         end
              @success = true
            when 401, 403
              # (403) the sender address can not be verified by SendGrid
              @error   = @faraday_result.status
              @message = (result_body.include?('errors') && result_body['errors'].is_a?(Array) && result_body['errors'].length.positive? && result_body['errors'][0].include?('message') ? result_body['errors'][0]['message'].inspect : 'Unknown')
              @success = false
            else
              @error   = @faraday_result&.status
              @message = (result_body.include?('errors') && result_body['errors'].is_a?(Array) && result_body['errors'].length.positive? && result_body['errors'][0].include?('message') ? result_body['errors'][0]['message'].inspect : 'Unknown')
              @success = false

              error = SendGridSendEmailError.new("Integrations::SendGrid::V1::Base.send_email: #{@message}")
              error.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(error) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action(error_message_prepend)

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(args)

                Appsignal.set_tags(
                  error_level: 'info',
                  error_code:  @error
                )
                Appsignal.add_custom_data(
                  api_key:                @api_key,
                  bcc_email:,
                  cc_email:,
                  client_id:              @client_id,
                  contact_id:,
                  data:,
                  faraday_result:         @faraday_result&.to_hash,
                  faraday_result_methods: @faraday_result&.public_methods.inspect,
                  from_email:,
                  result:                 @result,
                  success:                @success,
                  tenant:                 @tenant,
                  to_email:,
                  file:                   __FILE__,
                  line:                   __LINE__
                )
              end
            end
          rescue StandardError => e
            @message = "SendGrid: #{e.message}"
            @success = false

            ProcessError::Report.send(
              error_code:    @error,
              error_message: "Integrations::SendGrid::V1::Base.send_email: #{e.message}",
              variables:     {
                e:              e.inspect,
                e_message:      e.message,
                finished:       @faraday_result&.finished?.inspect,
                reason_phrase:  @faraday_result&.reason_phrase.inspect,
                result_methods: @faraday_result&.public_methods.inspect,
                status:         @faraday_result&.status.inspect,
                success:        @faraday_result&.success?.inspect,
                api_key:        @api_key.inspect,
                args:           args.inspect,
                bcc_email:      bcc_email.inspect,
                cc_email:       cc_email.inspect,
                client_id:      @client_id.inspect,
                contact_id:     contact_id.inspect,
                data:           data.inspect,
                from_email:     from_email.inspect,
                result:         @result.inspect,
                tenant:         @tenant.inspect,
                to_email:       to_email.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )

            @result
          end

          JsonLog.info 'Integrations::SendGrid::V1::Base.send_email', { success: @success, error_message: @message, error_code: @error, result: @result, faraday_result: @faraday_result }

          @result
        end

        private

        def base_url
          'https://api.sendgrid.com/'
        end

        def parse_email_addresses_from_headers(headers)
          cc = parse_email_addresses(headers.each_line.find { |line| line.match?(%r{^Cc: }) })
          from = parse_email_addresses(headers.each_line.find { |line| line.match?(%r{^From: }) })

          { cc:, from: }
        end

        def parse_email_addresses(line)
          return unless line

          list = Mail::AddressList.new(line.gsub('To: ', '').gsub('Cc: ', '').gsub('From: ', '').delete("\n"))
          list.addresses.map do |address|
            { name: address.display_name, email: address.address }
          end
        rescue StandardError => e
          JsonLog.error 'Integrations::SendGrid::V1::Base.parse_email_addresses', { error_message: e.message, class: e.class, line: }
          []
        end

        def reset_attributes
          @error          = 0
          @faraday_result = nil
          @message        = ''
          @success        = false
          @result         = {}
        end
      end
    end
  end
end

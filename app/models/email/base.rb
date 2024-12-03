# frozen_string_literal: true

# app/models/email/base.rb
module Email
  class Base
    attr_accessor :error, :message, :result, :success, :faraday_result
    alias success? success

    # Email::Base.client_send_emails?(client)
    def self.client_send_emails?(client)
      ClientApiIntegration.find_by(client_id: client.id, target: 'sendgrid')&.api_key.to_s.present? ||
        ClientApiIntegration.find_by(client_id: client.id, target: 'email', name: '')&.api_key.to_s.present?
    end

    # Email::Base.send(
    #   client: Client.find(1),
    #   from_email: {email: 'ian@ianneubert.com', name: 'ian neubert'},
    #   to_email: {name: 'ian neubert', email: 'ian@endeavorops.com'},
    #   subject: 'testing',
    #   content: "this is my email. testing."
    # )
    # email_client.send_email()
    #   (req) client: (Client)
    #     ~ or ~
    #   (req) client_id: (Integer)
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
    def send(args = {})
      raise ArgumentError, 'must include client or client_id' unless args.include?(:client) || args.include?(:client_id)

      # raise ArgumentError, 'must include to_email' unless args.include?(:to_email)
      # raise ArgumentError, 'to_email must be an array or an Email::Address' unless args[:to_email].is_a?(Array) || args[:to_email].is_a?(Email::Address)

      args[:to_email] = [args[:to_email]] unless args[:to_email].is_a?(Array)
      # raise ArgumentError, 'to_email must include at least one Email::Address' unless args[:to_email].empty? || !args[:to_email].first.is_a?(Email::Address)
      # raise ArgumentError, 'to_email must include only Email::Address' unless args[:to_email].map { |value| value.is_a?(Email::Address) }.uniq.length == 1 && args[:to_email].first.is_a?(Email::Address)

      client = args[:client_id].present? ? Client.find(args[:client_id]) : args[:client]

      sg_integration = client.client_api_integrations.find_by(target: 'sendgrid', name: '')
      email_integration = client.client_api_integrations.find_by(target: 'email', name: '')

      # change to_email so we don't accidently send message to random people in dev/test/staging
      unless Rails.env.production?
        args[:content].prepend "Original to: #{args[:to_email]}\n\n"

        dev_email = {
          email: ENV.fetch('SUPER_USER_EMAIL', 'kevin@chiirp.com'),
          name:  ''
        }
        dev_email[:name] = "#{Rails.env.titleize} Tester" if args[:to_email].first[:name].present?
        args[:to_email] = [dev_email]
      end

      if sg_integration&.api_key.present?
        # client has a SG integration
        sg_client = Integrations::SendGrid::V1::Base.new(
          client_id: client.id,
          api_key:   sg_integration.api_key,
          tenant:    client.tenant
        )
        res = sg_client.send_email(
          from_email:  args[:from_email],
          to_email:    args[:to_email],
          cc_email:    args[:cc_email],
          bcc_email:   args[:bcc_email],
          reply_email: args[:reply_email],
          subject:     args[:subject],
          content:     args[:content],
          contact_id:  args[:contact_id],
          attachments: args[:attachments]
        )

        @error = sg_client.error
        @message = sg_client.message
        @result = sg_client.result
        @success = sg_client.success

        res
      elsif email_integration&.api_key.present?
        # client as an email integration
        email_client = Integrations::EMail::V1::Base.new(email_integration.username, email_integration.api_key, client.id, tenant: client.tenant)
        res = email_client.send_email(
          from_email:  args[:from_email],
          to_email:    args[:to_email],
          cc_email:    args[:cc_email],
          bcc_email:   args[:bcc_email],
          reply_email: args[:reply_email],
          subject:     args[:subject],
          content:     args[:content],
          contact_id:  args[:contact_id],
          attachments: args[:attachments]
        )

        @error = email_client.error
        @message = email_client.message
        @result = email_client.result
        @success = email_client.success
        @faraday_result = email_client.faraday_result

        res
      else
        false
      end
    end

    # Send an email from the internal Chiirp SendGrid account: chiirp.io
    # Email::Base.send_from_internal(
    #   to_email: {name: 'ian neubert', email: 'ian@endeavorops.com'},
    #   subject: 'testing',
    #   content: "this is my email. testing."
    # )
    # email_client.send_email()
    #   (req) to_email:   (Array)
    #           [{ email: '', name: ''}]
    #   (req) subject:    (String)
    #   (req) content:    (String)
    #   (req) client_id: (Integer)
    def send_from_internal(args = {})
      raise ArgumentError, 'must include client or client_id' unless args.include?(:client) || args.include?(:client_id)

      client = args[:client_id].present? ? Client.find(args[:client_id]) : args[:client]
      sg_client = Integrations::SendGrid::V1::Base.new(
        client_id: args[:client_id],
        api_key:   Rails.application.credentials[:sendgrid][:chiirp],
        tenant:    client.tenant
      )
      from_address = { email: 'no-reply@chiirp.io', name: "#{I18n.t('tenant.name')} Notification" }

      res = sg_client.send_email(
        from_email:  from_address,
        reply_email: from_address,
        to_email:    args[:to_email],
        subject:     args[:subject],
        content:     args[:content]
      )

      @error = sg_client.error
      @message = sg_client.message
      @result = sg_client.result
      @success = sg_client.success
      @faraday_result = sg_client.faraday_result

      res
    end
  end
end

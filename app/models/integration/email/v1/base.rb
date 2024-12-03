# frozen_string_literal: true

# app/models/integration/email/v1/base.rb
module Integration
  module Email
    module V1
      class Base
        attr_reader :client_api_integration, :email_client, :user_id

        # @client_api_integration = ClientApiIntegration.find(client_id); em_model = Integration::Email::V1::Base.new(@client_api_integration); em_client = Integrations::EMail::V1::Base.new(@client_api_integration.username, Rails.application.credentials[:sendgrid][:chiirp], @client_api_integration.client_id)
        def initialize(client_api_integration)
          @client_api_integration = client_api_integration
          @email_client = Integrations::EMail::V1::Base.new(@client_api_integration.username, Rails.application.credentials[:sendgrid][:chiirp], @client_api_integration.client_id)
        end

        def connected?
          return true if @client_api_integration.mail_cname['host'].present? && @client_api_integration.dkim1['host'].present? && @client_api_integration.dkim2['host'].present? &&
                         @client_api_integration.mail_cname['data'].present? && @client_api_integration.dkim1['data'].present? && @client_api_integration.dkim2['data'].present?

          false
        end

        def create_account
          @client_api_integration.password = @client_api_integration.password.presence || RandomCode.new.create(20, req_integer: true)
          @client_api_integration.save
          email_client.create_subaccount(@client_api_integration.email, @client_api_integration.password, @client_api_integration.ips)

          res = email_client.create_api_keys(@client_api_integration.username, %w[mail.send])
          @client_api_integration.api_key = res.dig(:api_key).to_s
          @client_api_integration.save

          if (res = email_client.create_domain(@client_api_integration.domain)).present?
            @client_api_integration.domain_id = res.dig(:id)
            @client_api_integration.mail_cname['host'] = res.dig(:dns, :mail_cname, :host)
            @client_api_integration.mail_cname['data'] = res.dig(:dns, :mail_cname, :data)
            @client_api_integration.dkim1['host'] = res.dig(:dns, :dkim1, :host)
            @client_api_integration.dkim1['data'] = res.dig(:dns, :dkim1, :data)
            @client_api_integration.dkim2['host'] = res.dig(:dns, :dkim2, :host)
            @client_api_integration.dkim2['data'] = res.dig(:dns, :dkim2, :data)
            @client_api_integration.save
          end

          html = Integrations::Email::V1::ConnectionsController.render partial: 'integrations/email/v1/menu', assigns: { client_api_integration: @client_api_integration }
          ClientCable.new.broadcast client_api_integration.client, { append: 'yes', id: 'email_page_nav', html: }

          html = Integrations::Email::V1::ConnectionsController.render partial: 'integrations/email/v1/connections/edit', assigns: { client_api_integration: @client_api_integration }
          ClientCable.new.broadcast client_api_integration.client, { append: 'yes', id: 'email_integration_page_section', html: }
        end

        def delete_account
          email_client.delete_account

          # erase domain/email/dkim data
          @client_api_integration.update api_key: '', password: '', domain_id: nil, mail_cname: {}, dkim1: {}, dkim2: {}, domain: '', ips: []

          html = Integrations::Email::V1::ConnectionsController.render partial: 'integrations/email/v1/menu', assigns: { client_api_integration: @client_api_integration }
          ClientCable.new.broadcast client_api_integration.client, { append: 'yes', id: 'email_page_nav', html: }

          html = Integrations::Email::V1::ConnectionsController.render partial: 'integrations/email/v1/connections/edit', assigns: { client_api_integration: @client_api_integration }
          ClientCable.new.broadcast client_api_integration.client, { append: 'yes', id: 'email_integration_page_section', html: }
        end

        def verify_domain
          res = email_client.verify_domain(@client_api_integration.domain_id)
          @client_api_integration.mail_cname['valid'] = res.dig(:validation_results, :mail_cname, :valid)
          @client_api_integration.mail_cname['reason'] = res.dig(:validation_results, :mail_cname, :reason)
          @client_api_integration.dkim1['valid'] = res.dig(:validation_results, :dkim1, :valid)
          @client_api_integration.dkim1['reason'] = res.dig(:validation_results, :dkim1, :reason)
          @client_api_integration.dkim2['valid'] = res.dig(:validation_results, :dkim2, :valid)
          @client_api_integration.dkim2['reason'] = res.dig(:validation_results, :dkim2, :reason)
          @client_api_integration.save

          html = Integrations::Email::V1::ConnectionsController.render partial: 'integrations/email/v1/menu', assigns: { client_api_integration: @client_api_integration }
          ClientCable.new.broadcast client_api_integration.client, { append: 'yes', id: 'email_page_nav', html: }

          html = Integrations::Email::V1::DomainVerificationsController.render partial: 'integrations/email/v1/domain_verifications/show', assigns: { client_api_integration: @client_api_integration }
          ClientCable.new.broadcast client_api_integration.client, { append: 'yes', id: 'email_integration_page_section', html: }
        end

        # delegate :send_email, to: :client

        def to_hash
          @client_api_integration.attributes
        end

        def valid_credentials?
          @email_client.valid_credentials?
        end
      end
    end
  end
end

# This code can be used to help find clients that might have a bad mail_cname
# ClientApiIntegration.where(target: 'email').each do |cai|
#   next if cai.mail_cname.dig('valid')

#   puts "#{cai.id}: #{cai.domain}" if cai.mail_cname.dig('host').present? && cai.mail_cname.dig('reason').present?
# end;1

# Find all ClientApiIntegrations with email target that have a domain but no username
# ClientApiIntegration.where(target: 'email').filter { |cai| cai.username == '' && cai.domain != '' }

###############
# Fix clients that did not init correctly with sendgrid
###############
# cais = []
# cais << ClientApiIntegration.find()

# cais.each do |cai|
#   cai.update! username: "sg-chiirp-client-production-#{cai.client.id}"
#   cai.update! ips: ['149.72.26.131']

#   # create subuser
#   em_model = Integration::Email::V1::Base.new(cai)
#   em_model.create_account
# end

# ensure each domain in sendgrid has a subuser
# https://api.sendgrid.com/v3/whitelabel/domains/<domain_id>/subuser

# ensure each domain in sendgrid has ips
# https://api.sendgrid.com/v3/whitelabel/domains/<domain_id>/ips

# ensure each subuser in sendgrid has ips
# https://api.sendgrid.com/v3/send_ips/ips/149.72.26.131/subusers:batchAdd
###############
################

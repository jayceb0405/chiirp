# frozen_string_literal: true

# app/controllers/integrations/sendgrid/v1/integrations_controller.rb
module Integrations
  module Sendgrid
    module V1
      class IntegrationsController < ApplicationController
        include Integrations::Sendgrid::Images
        include Integrations::Sendgrid::Utils

        skip_parameter_encoding :endpoint
        skip_before_action :verify_authenticity_token, only: %i[bounced endpoint]
        before_action :authenticate_user!, except: %i[bounced endpoint]
        before_action :authorize_user!, except: %i[bounced endpoint]
        before_action :authenticate_webhook!, only: %i[bounced]
        before_action :client, except: %i[bounced endpoint]
        before_action :client_api_integration, except: %i[bounced endpoint]

        # receive bounced/spam/unsubscribe emails from all SendGrid accounts
        #   **INCLUDING** sub accounts using email integration
        # /integrations/sendgrid/bounced
        # integrations_sendgrid_bounced_path
        # integrations_sendgrid_bounced_url
        def bounced
          params.dig(:_json)&.each do |sg_message|
            if (message_sid = sg_message.dig(:sg_message_id)&.split('.')&.first)
              next if (message = Messages::Message.find_by(message_sid:)).blank?

              message.contact&.update ok2email: false

              case sg_message.dig(:event) # bounce, spamreport, unsubscribe
              when 'bounce'
                message.update error_code:    sg_message.dig(:reason).split.first,
                               error_message: sg_message.dig(:reason),
                               status:        sg_message.dig(:type)
              when 'spamreport', 'unsubscribe'
                message.update error_code:    sg_message.dig(:event),
                               error_message: sg_message.dig(:event) == 'unsubscribe' ? 'Recipient unsubscribed' : 'Recipient reported spam'
              end
            end
          end

          render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok
        end
        # params ex:
        # {
        #   "_json"=>[
        #     {
        #       "bounce_classification"=>"Reputation",
        #       "email"=>"mattie-renewlm@outlook.com",
        #       "event"=>"bounce",
        #       "ip"=>"167.89.78.126",
        #       "reason"=>"550 5.7.1 Unfortunately, messages from [167.89.78.126] weren't sent. Please contact your Internet service provider since part of their network is on our block list (S3150). You can also refer your provider to http://mail.live.com/mail/troubleshooting.aspx#errors. [DB5PEPF00014B9E.eurprd02.prod.outlook.com 2024-02-29T17:37:31.864Z 08DC33CF4D83F02D]",
        #       "sg_event_id"=>"Ym91bmNlLTAtOTQzNDUyMi1RTEZCSUV5QlNpNm1XcUhVVGc4N1l3LTA",
        #       "sg_message_id"=>"QLFBIEyBSi6mWqHUTg87Yw.filterdrecv-d585b8d85-kx4qj-1-65E0C0DA-1D.0",
        #       "smtp-id"=>"<QLFBIEyBSi6mWqHUTg87Yw@geopod-ismtpd-28>",
        #       "status"=>"5.7.1",
        #       "timestamp"=>1709228251,
        #       "tls"=>1,
        #       "type"=>"blocked"
        #     }
        #   ]
        # }

        # receive incoming email from SendGrid
        # /integrations/sendgrid/endpoint
        # integrations_sendgrid_endpoint_path
        # integrations_sendgrid_endpoint_url
        def endpoint
          sg_client = Integrations::SendGrid::V1::Base.new
          sg_client.parse_email(params_email)

          respond_to do |format|
            format.json { render json: { status: 200, message: 'success' } }
            format.html { render plain: 'success', content_type: 'text/plain', layout: false, status: :ok }
          end

          return unless sg_client.success?

          sg_client.result[:to].each do |to_email|
            next unless (client_api_integration = ClientApiIntegration.find_by("data ->> 'email_addresses' LIKE ?", "%#{to_email}%"))

            if (contact = Contact.find_by(client_id: client_api_integration.client_id, email: sg_client.result[:from][:email]))
              message = contact.messages.create(
                account_sid:   0,
                automated:     false,
                cost:          0,
                error_code:    '',
                error_message: '',
                from_phone:    sg_client.result[:from][:email],
                message:       sg_client.result[:subject].to_s,
                message_sid:   0,
                msg_type:      'emailin',
                status:        'received',
                to_phone:      to_email
              )

              message_email = message.create_email(
                text_body:  sg_client.result[:text_body],
                html_body:  sg_client.result[:html_body],
                headers:    sg_client.result[:headers],
                to_emails:  sg_client.result[:to],
                cc_emails:  sg_client.result[:cc],
                bcc_emails: sg_client.result[:bcc]
              )

              attach_images(message_email, sg_client.result[:attachment_info])

              show_live_messenger = ShowLiveMessenger.new(message:)
              show_live_messenger.queue_broadcast_active_contacts
              show_live_messenger.queue_broadcast_message_thread_message
            elsif sg_client.result[:from].casecmp?('no-reply@sendgrid.com')

              User.where(client: client_api_integration.client_id).where('permissions @> ?', { integrations_controller: ['client'] }.to_json).find_each do |user|
                next if Rails.env.development? && user.id != 3 # only send to Kevin if development

                user.send_email(subject: "#{I18n.t('tenant.name')} Email Error", content: sg_client.result[:html_body].presence || sg_client.result[:text_body])
              end
            end
          end
        end

        # (GET) show SendGrid integration Overview
        # /integrations/sendgrid
        # integrations_sendgrid_v1_path
        # integrations_sendgrid_v1_url
        def show
          respond_to do |format|
            format.js { render partial: 'integrations/sendgrid/v1/js/show', locals: { cards: %w[overview] } }
            format.html { render 'integrations/sendgrid/v1/show' }
          end
        end

        private

        def authenticate_webhook!
          return if params[:token] == Rails.application.credentials.dig(:sendgrid, :webhook_token)

          render plain: 'unauthorized', content_type: 'text/plain', layout: false, status: :unauthorized and return false
        end

        def authorize_user!
          super

          return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('sendgrid')

          sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access SendGrid Integrations. Please contact your account admin.', '', { persistent: 'OK' })

          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { redirect_to root_path and return false }
          end
        end

        def client
          @client = current_user.client
        end

        def client_api_integration
          return if (@client_api_integration = ClientApiIntegration.find_or_create_by(client_id: @client.id, target: 'sendgrid'))

          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { redirect_to root_path and return false }
          end
        end
      end
    end
  end
end

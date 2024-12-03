# frozen_string_literal: true

# app/controllers/integrations/email/v1/integrations_controller.rb
module Integrations
  module Email
    module V1
      class IntegrationsController < ApplicationController
        include Integrations::Sendgrid::Images
        include Integrations::Sendgrid::Utils

        # https://github.com/rails/rails/issues/41567
        # https://github.com/rails/rails/issues/42278
        skip_parameter_encoding :inbound
        skip_before_action :verify_authenticity_token, only: %i[inbound]
        before_action :authenticate_user!, except: %i[inbound]
        before_action :authorize_user!, except: %i[inbound]
        before_action :client_api_integration, except: %i[inbound]
        before_action :verify_key, only: %i[inbound]

        def inbound
          sg_client = Integrations::SendGrid::V1::Base.new
          sg_client.parse_email(params_email)

          JsonLog.info 'Integrations::Email::V1::IntegrationsController.inbound', { result: sg_client.result }

          respond_to do |format|
            format.json { render json: { status: 200, message: 'success' } }
            format.html { render plain: 'success', content_type: 'text/plain', layout: false, status: :ok }
          end

          return unless sg_client.success?

          sg_client.result[:to].each do |to_email|
            next unless %r{chiirp.io$}.match?(to_email[:email].split('@').last) # only process emails sent to *chiirp.io
            next unless (client_api_integration = ClientApiIntegration.where(target: 'email').find_by("data ->> 'inbound_username' LIKE ?", "#{to_email[:email].split('@').first}%"))

            contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client_api_integration.client_id, emails: [sg_client.result[:from][:email]])
            # assign contact name if possible
            if contact.firstname == 'Friend' && sg_client.result[:from][:name].present?
              name = sg_client.result[:from][:name].parse_name
              if name[:middlename].present?
                contact.firstname = sg_client.result[:from][:name]
              else
                contact.firstname = name[:firstname]
                contact.lastname = name[:lastname]
              end
            end
            contact.save

            message = contact.messages.create(
              account_sid:   0,
              automated:     false,
              cost:          0,
              error_code:    '',
              error_message: '',
              from_phone:    sg_client.result[:from][:email].to_s,
              message:       sg_client.result[:subject].to_s,
              message_sid:   0,
              msg_type:      'emailin',
              status:        'received',
              to_phone:      to_email[:email]
            )

            message_email = message.create_email(
              text_body:  sg_client.result[:text_body].encode('UTF-8', invalid: :replace, undef: :replace, replace: "\uFFFD"),
              html_body:  sg_client.result[:html_body].encode('UTF-8', invalid: :replace, undef: :replace, replace: "\uFFFD"),
              headers:    sg_client.result[:headers].encode('UTF-8', invalid: :replace, undef: :replace, replace: "\uFFFD"),
              to_emails:  sg_client.result[:to],
              cc_emails:  sg_client.result[:cc],
              bcc_emails: sg_client.result[:bcc]
            )

            attach_images(message_email, sg_client.result[:attachment_info])

            show_live_messenger = ShowLiveMessenger.new(message:)
            show_live_messenger.queue_broadcast_active_contacts
            show_live_messenger.queue_broadcast_message_thread_message
          end
        end

        def show
          respond_to do |format|
            format.js { render partial: 'integrations/email/v1/js/show', locals: { cards: %w[menu overview] } }
            format.html { render 'integrations/email/v1/show' }
          end
        end

        private

        def client_api_integration
          return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'email', name: ''))

          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { redirect_to root_path and return false }
          end
        end

        def verify_key
          return if params[:token] == Rails.application.credentials.dig(:email, :sendgrid_inbound_token)

          render plain: 'unauthorized', content_type: 'text/plain', layout: false, status: :unauthorized and return false
        end
      end
    end
  end
end

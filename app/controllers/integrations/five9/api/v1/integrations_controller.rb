# frozen_string_literal: true

# app/controllers/integrations/five9/api/v1/integrations_controller.rb
module Integrations
  module Five9
    module Api
      module V1
        # integration endpoints supporting Five9 SMS/MMS transfer
        class IntegrationsController < ApplicationController
          skip_before_action :verify_authenticity_token, only: %i[dispendpoint mcendpoint msendpoint]

          # (POST) support for processing Five9 dispositions
          # /integrations/five9/api/v1/endpoints/disposition
          # integrations_five9_api_v1_dispendpoint_path
          # integrations_five9_api_v1_dispendpoint_url
          def dispendpoint
            sanitized_params = params.permit(:user_name, :number, :disposition_name)
            email            = sanitized_params.dig(:user_name).to_s
            phone            = sanitized_params.dig(:number).to_s
            disposition_name = sanitized_params.dig(:disposition_name).to_s

            if email.present? && phone.present? && disposition_name.present? &&
               (user = User.find_by(email:)) &&
               (client_api_integration = ClientApiIntegration.find_by(client_id: user.client_id, target: 'five9')) &&
               ((disposition = client_api_integration.dispositions.find { |disp| disp['id'] == disposition_name.tr(' ', '_') }) &&
               (contact = Contact.joins(:contact_phones).find_by(client_id: user.client_id, contact_phones: { phone: })))

              disposition = disposition.symbolize_keys

              contact.process_actions(
                campaign_id:       disposition[:campaign_id],
                group_id:          disposition[:group_id],
                stage_id:          disposition[:stage_id],
                tag_id:            disposition[:tag_id],
                stop_campaign_ids: disposition[:stop_campaign_ids]
              )
            end

            render plain: 'Success', content_type: 'text/plain', layout: false, status: :ok
          end

          # (POST) support for processing Five9 / Message Central screen pops
          # /integrations/five9/api/v1/endpoints/central
          # integrations_five9_api_v1_mcendpoint_path
          # integrations_five9_api_v1_mcendpoint_url
          def mcendpoint
            sanitized_params = params.permit(:user_name, :number, :number1, :type, :campaign_name)
            user_email       = sanitized_params.dig(:user_name).to_s
            phone            = sanitized_params.dig(:number)
            phone            = sanitized_params.dig(:number1) if phone.blank?
            type             = sanitized_params.dig(:type).to_s.downcase
            campaign_name    = sanitized_params.dig(:campaign_name).to_s

            if user_email.present? && (user = User.find_by(email: user_email))
              tenant              = user.client.tenant
              tenant_app_host     = I18n.with_locale(tenant) { I18n.t("tenant.#{Rails.env}.app_host") }
              tenant_app_protocol = I18n.with_locale(tenant) { I18n.t('tenant.app_protocol') }
              phone               = phone.to_s.clean_phone(user.client.primary_area_code)

              if phone.present?

                unless (contact = Contact.joins(:contact_phones).find_by(client_id: user.client_id, contact_phones: { phone: }))
                  contact = user.contacts.create(firstname: 'Friend')
                  contact.contact_phones.create(label: 'mobile', phone:)
                end

                if contact
                  RedisCloud.redis.setex("contact:#{contact.id}:five9_booking_campaign_name", 3600, campaign_name.tr(' ', '_')) if campaign_name.present?
                  RedisCloud.redis.setex("contact:#{contact.id}:five9_incoming_phone", 3600, phone) if phone.present?

                  if Users::RedisPool.new(user.id).controller_name == 'central' && Users::RedisPool.new(user.id).action_name == 'index'
                    UserCable.new.broadcast user.client, user, { chiirp_alert: {
                      type:                'info',
                      title:               "Incoming #{type == 'voice' ? 'Call' : 'Text'}",
                      body:                "#{type == 'voice' ? 'Call' : 'Text'} from #{contact.fullname} (#{ActionController::Base.helpers.number_to_phone(phone)}).",
                      persistent:          true,
                      cancel_button_text:  'Close',
                      confirm_button_text: 'Go To Contact',
                      data_type:           'script',
                      url:                 central_conversation_path(contact_id: contact.id, host: tenant_app_host, protocol: tenant_app_protocol, active_tab: 'contact_profile')
                    } }
                  else
                    UserCable.new.broadcast user.client, user, { chiirp_alert: {
                      type:                'info',
                      title:               "Incoming #{type == 'voice' ? 'Call' : 'Text'}",
                      body:                "#{type == 'voice' ? 'Call' : 'Text'} from #{contact.fullname} (#{ActionController::Base.helpers.number_to_phone(phone)}).",
                      persistent:          true,
                      cancel_button_text:  'Close',
                      confirm_button_text: 'Go To Message Central',
                      url:                 central_url(contact_id: contact.id, host: tenant_app_host, protocol: tenant_app_protocol, active_tab: 'contact_profile')
                    } }
                  end
                else
                  UserCable.new.broadcast user.client, user, { chiirp_alert: {
                    type:       'info',
                    title:      "Incoming #{type == 'voice' ? 'Call' : 'Text'}",
                    body:       "#{type == 'voice' ? 'Call' : 'Text'} from #{ActionController::Base.helpers.number_to_phone(phone)}. Unable to locate or create Contact.",
                    persistent: false
                  } }
                end
              end
            end

            render plain: 'Success', content_type: 'text/plain', layout: false, status: :ok
          end

          # (POST) support for processing Five9 text messages pass through
          # /integrations/five9/api/v1/endpoints/msg
          # integrations_five9_api_v1_msendpoint_path
          # integrations_five9_api_v1_msendpoint_url
          def msendpoint
            if params.dig(:applicationId).to_s == Rails.application.credentials[:five9][:api_key]
              from_phone = params.dig(:from).to_s.sub('+1', '')
              to_phone   = params.dig(:to).is_a?(Array) ? params.dig(:to).first.to_s.sub('+1', '') : params.dig(:to).to_s.sub('+1', '')

              if (client = Client.joins(:twnumbers).find_by(twnumbers: { phonenumber: from_phone })) &&
                 (contact = Contact.joins(:contact_phones).find_by(client_id: client.id, contact_phones: { phone: to_phone }))

                image_id_array = if params.dig(:media).present? && (client_api_integration = ClientApiIntegration.find_by(client_id: client.id, target: 'five9', name: ''))
                                   Integrations::FiveNine::Base.new(client_api_integration.credentials).call(:attach_media_to_contact, { contact:, media_array: params.dig(:media) })
                                 else
                                   []
                                 end

                contact.delay(
                  priority:            DelayedJob.job_priority('send_text'),
                  queue:               DelayedJob.job_queue('send_text'),
                  contact_id:          contact.id,
                  user_id:             contact.user_id,
                  triggeraction_id:    0,
                  contact_campaign_id: 0,
                  data:                { content: params.dig(:text), image_id_array: },
                  process:             'send_text'
                ).send_text(
                  from_phone:,
                  to_phone:,
                  content:        params.dig(:text),
                  image_id_array:,
                  msg_type:       'textout'
                )
                render plain: 'Success', content_type: 'text/plain', layout: false, status: :ok
              else
                render plain: 'Unknown Client or Contact', content_type: 'text/plain', layout: false, status: :not_found
              end
            else
              render plain: 'Unauthorized', content_type: 'text/plain', layout: false, status: :forbidden
            end
          end
          # sample of JSON data expected from Five9
          # {
          #   "to"=>["+18023455136"],
          #   "from"=>"+18022898010",
          #   "text"=>"Testing Five9 text.",
          #   "applicationId"=>"5e8b5ec9-65bf-4342-a18e-27b3fc355e65"
          # }
        end
      end
    end
  end
end

# frozen_string_literal: true

# app/controllers/api/chiirpapp/v1/conversations_controller.rb
module Api
  module Chiirpapp
    module V1
      class ConversationsController < ChiirpappApiController
        before_action :contact, only: %i[call_contact contact_phone_numbers index send_message update_message]
        before_action :twnumber, only: %i[call_history]

        # (POST) call a Contact
        # /api/chiirpapp/v1/user/:user_id/conversations/:contact_id/call
        # api_chiirpapp_v1_user_call_contact_path(:user_id, :contact_id)
        # api_chiirpapp_v1_user_call_contact_url(:user_id, :contact_id)
        def call_contact
          sanitized_params = params.permit(:from_phone, :to_phone, :contact_id)
          from_phone       = (sanitized_params.dig(:from_phone).presence || @user.default_from_twnumber&.phonenumber).to_s
          to_phone         = (sanitized_params.dig(:to_phone).presence || @contact.primary_phone&.phone).to_s

          if from_phone.present?
            # Connect an outbound call to Contact & User
            result = @contact.call(users_orgs: "user_#{@user.id}", from_phone:, contact_phone: to_phone)

            if result[:success]
              render json: { message: 'Phone call connected.', status: :ok }
            else
              render json: { message: "Phone call could NOT be connected. #{result[:error_message]}", status: :service_unavailable }
            end
          else
            render json: { message: 'Phone call could NOT be connected. Your phone number is empty.', status: :service_unavailable }
          end
        end

        # (GET) get call history for a specific Twnumber
        # /api/chiirpapp/v1/user/:user_id/conversations/call_history/:phone_number
        # api_chiirpapp_v1_user_call_history_path(:user_id, :phone_number)
        # api_chiirpapp_v1_user_call_history_url(:user_id, :phone_number)
        #   (req) user_id:      (Integer)
        #   (req) phone_number: (String)
        #   (opt) starttime:    (String)  default: <perioddays> days prior to <endtime>
        #   (opt) endtime:      (String)  default: current time
        #   (opt) perioddays:   (Integer) default: 30
        #   (opt) sortorder:    (String)  default: 'desc'
        def call_history
          sanitized_params = params.permit(:endtime, :perioddays, :sortorder, :starttime)
          sort_order       = (sanitized_params.dig(:sortorder).presence || 'desc').to_s
          period_days      = (sanitized_params.dig(:perioddays).presence || 30).to_i
          end_time         = Time.use_zone(@user.client.time_zone) { Chronic.parse(sanitized_params.dig(:endtime).presence || Time.current.to_s) }.utc
          start_time       = Time.use_zone(@user.client.time_zone) { Chronic.parse(sanitized_params.dig(:starttime).presence || (end_time - period_days.days).to_s) }.utc

          render json: [].to_json, layout: false, status: :bad_request and return if end_time < start_time

          response = Messages::Message.select(:message, :created_at, :from_phone, :to_phone)
                                      .select('"contacts"."id" AS contact_id, "contacts"."lastname" AS contact_lastname, "contacts"."firstname" AS contact_firstname')
                                      .joins(:contact)
                                      .where(msg_type: Messages::Message::MSG_TYPES_VOICE, to_phone: @twnumber.phonenumber, created_at: start_time..end_time)
                                      .or(
                                        Messages::Message.select(:message, :created_at, :from_phone, :to_phone)
                                                         .select('"contacts"."id" AS contact_id, "contacts"."lastname" AS contact_lastname, "contacts"."firstname" AS contact_firstname')
                                                         .joins(:contact)
                                                         .where(msg_type: Messages::Message::MSG_TYPES_VOICE, from_phone: @twnumber.phonenumber, created_at: start_time..end_time)
                                      ).order(created_at: sort_order.to_sym)

          render json: response.to_json, layout: false, status: :ok
        end

        # (GET) return current contact info for both User & Contact
        # /api/chiirpapp/v1/user/:user_id/conversations/:contact_id
        # api_chiirpapp_v1_user_conversation_contact_path(:user_id, :contact_id)
        # api_chiirpapp_v1_user_conversation_contact_url(:user_id, :contact_id)
        def contact_phone_numbers
          response = {}

          response[:user_phone_number_selected]    = @contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s
          response[:contact_phone_number_selected] = @contact.latest_contact_phone_by_label(label: 'mobile')
          response[:user_phone_numbers]            = ApplicationController.helpers.options_for_phone_numbers_array(contact: @contact, current_user: (@user.access_controller?('central', 'all_contacts', session) ? user : nil))
          response[:contact_phone_numbers]         = case response[:contact_phone_number_selected]
                                                     when 'all', 'fb', 'ggl', 'email', 'widget'
                                                       []
                                                     else
                                                       ContactPhone.contact_phones_for_select(@contact.id)
                                                     end

          render json: response.to_json, layout: false, status: :ok
        end

        # upload a file for a text message
        # /api/chiirpapp/v1/user/:user_id/conversations/file_upload
        # api_chiirpapp_v1_user_file_upload_path(:user_id)
        # api_chiirpapp_v1_user_file_upload_url(:user_id)
        def file_upload
          file_id       = 0
          file_url      = ''
          error_message = ''

          if params.include?(:file)
            begin
              # upload into Client images folder
              user_attachment = @user.user_attachments.create!(image: params[:file])

              file_url = user_attachment.image.thumb.url(resource_type: user_attachment.image.resource_type, secure: true)
              retries = 0

              while file_url.nil? && retries < 10
                retries += 1
                sleep ProcessError::Backoff.full_jitter(retries:)
                user_attachment.reload
                file_url = user_attachment.image.thumb.url(resource_type: user_attachment.image.resource_type, secure: true)
              end
            rescue StandardError => e
              e.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(e) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action('Api::Chiirpapp::V1::ConversationsController#file_upload')

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(params)

                Appsignal.set_tags(
                  error_level: 'error',
                  error_code:  0
                )
                Appsignal.add_custom_data(
                  retries:,
                  file_url:,
                  user_attachment:,
                  file:            __FILE__,
                  line:            __LINE__
                )
              end

              user_attachment = nil
              file_url        = ''
              error_message   = 'An error was encountered while attempting to upload your file. Please try again.'
            end
          else
            user_attachment = nil
            error_message   = 'File was NOT received.'
          end

          file_id = user_attachment.id if user_attachment

          render json: { fileId: file_id, fileUrl: file_url, errorMessage: error_message, status: 200 }
        end

        # (GET) return Conversation message array
        # /api/chiirpapp/v1/user/:user_id/conversations
        # api_chiirpapp_v1_user_conversations_path(:user_id)
        # api_chiirpapp_v1_user_conversations_url(:user_id)
        def index
          sanitized_params = params.permit(:current_phone_number)

          contact_message_thread = []

          Messages::Message.contact_message_thread(contact: @contact, current_phone_number: sanitized_params.dig(:current_phone_number) || 'all').each do |message|
            if message.attachments.any?
              attachments = []
              message.attachments.each do |message_attachment|
                attachments << {
                  thumb: message_attachment.contact_attachment.image.thumb.url(resource_type: message_attachment.contact_attachment.image.resource_type, secure: true),
                  full:  message_attachment.contact_attachment.image.url(resource_type: message_attachment.contact_attachment.image.resource_type, secure: true)
                }
              end

              contact_message_thread << message.attributes.merge({ attachments: })
            else
              contact_message_thread << message.attributes
            end
          end

          render json: contact_message_thread.to_json, layout: false, status: :ok
        end

        # (PUT) update a Messages::Message
        # /api/chiirpapp/v1/user/:user_id/conversations/:contact_id/message/:message_id
        # api_chiirpapp_v1_user_update_message_path(:user_id, :contact_id, :message_id)
        # api_chiirpapp_v1_user_update_message_url(:user_id, :contact_id, :message_id)
        def update_message
          if params.include?(:read)

            if (message = @contact.messages.find_by(id: params[:message_id]))
              message.update(read_at: params[:read].to_bool ? Time.current : nil)
              render json: { message: 'Message updated.', status: :ok }
            else
              render json: { message: 'Message NOT found.', status: :not_found }
            end
          else
            render json: { message: 'Message NOT updated.', status: :bad_request }
          end
        end

        # (POST) send a message to a Contact
        # /api/chiirpapp/v1/user/:user_id/conversations/:contact_id/send
        # api_chiirpapp_v1_user_conversation_send_path(:user_id, :contact_id)
        # api_chiirpapp_v1_user_conversation_send_url(:user_id, :contact_id)
        def send_message
          sanitized_params = params.permit(:contact_ids, :file_attachments, :from_phone, :message, :msg_delay, :msg_type, :to_phone, :user_id)
          file_attachments = JSON.parse(sanitized_params.dig(:file_attachments) || '{}').collect(&:symbolize_keys)

          bubble = Messages::SendMessage.new(
            from_phone: sanitized_params.dig(:from_phone),
            message:    sanitized_params.dig(:message),
            msg_delay:  Chronic.parse(sanitized_params.dig(:msg_delay)),
            msg_type:   sanitized_params.dig(:msg_type),
            to_phone:   sanitized_params.dig(:to_phone)
          ).send(
            contact_ids:      sanitized_params.dig(:contact_ids),
            contact_id:       @contact.id,
            file_attachments:,
            user_id:          sanitized_params.dig(:user_id)
          )

          render json: bubble.to_json, layout: false, status: :ok
        end
      end
    end
  end
end

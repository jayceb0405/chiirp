# frozen_string_literal: true

# app/controllers/integrations/google/messages_controller.rb
module Integrations
  module Google
    class MessagesController < Google::IntegrationsController
      skip_before_action :verify_authenticity_token, only: %i[endpoint]
      skip_before_action :authenticate_user!, only: %i[endpoint]
      skip_before_action :authorize_user!, only: %i[endpoint]
      skip_before_action :client_api_integration, only: %i[endpoint]
      skip_before_action :update_client_api_integration_user_id, only: %i[endpoint]
      skip_before_action :user_api_integration, only: %i[endpoint]
      before_action :authorize_user_for_messages!, except: %i[endpoint]
      # (POST) receive Google Messages
      # /integrations/google/messages/endpoint
      # integrations_google_messages_endpoint_path
      # integrations_google_messages_endpoint_url
      def endpoint
        if params.dig(:clientToken).present? && params.dig(:secret).present?
          respond_to do |format|
            format.json { render json: { status: 200, message: params.dig(:secret) } and return }
            format.html { render plain: params.dig(:secret), content_type: 'text/plain', layout: false, status: :ok and return }
          end
        elsif params.dig(:message).present?
          sanitized_params = params.permit(:agent, :conversationId)
          sanitized_params.merge!(params.require(:message).permit(:messageId, :name, :text)) if params.key?('message')
          sanitized_params.merge!(params.require(:context).permit(userInfo: [:displayName])) if params.key?('context')
          sanitized_params.merge!(params.require(:receipts).permit(receipts: %i[message receiptType])) if params.key?('receipts')
          agent_id         = sanitized_params.dig(:agent).to_s
          content          = sanitized_params.dig(:text).to_s
          conversation_id  = "conversations/#{sanitized_params.dig(:conversationId)}"
          fullname         = sanitized_params.dig(:userInfo, :displayName).to_s
          media_url        = ''
          message_id       = sanitized_params.dig(:name).to_s
          receipts         = sanitized_params.dig(:receipts)

          if agent_id.present? && content.present? && conversation_id.present? && message_id.present? && fullname.present?
            parsed_name = fullname.parse_name

            if content.start_with?('https://storage.googleapis.com/business-messages-us')
              media_url = content
              content   = ''
            end

            ClientApiIntegration.where(target: 'google', name: '').where("data -> 'agents' @> ?", agent_id.to_json).find_each do |client_api_integration|
              if (contact = client_api_integration.client.contacts.joins(:ggl_conversations).find_by(ggl_conversations: { conversation_id: }) || Contact.find_by_closest_match(client_api_integration.client_id, parsed_name.dig(:lastname).to_s, parsed_name.dig(:firstname).to_s) || client_api_integration.client.contacts.create(lastname: parsed_name.dig(:lastname).to_s, firstname: parsed_name.dig(:firstname).to_s))

                location_id       = client_api_integration.active_locations_messages&.each { |_key, values| values.find { |_k, v| v.dig('agent_id').to_s == agent_id } }&.values&.first&.keys&.first.to_s
                contact.firstname = parsed_name.dig(:firstname) if (contact.firstname.blank? || contact.firstname.casecmp?('friend')) && parsed_name.dig(:firstname).present?
                contact.lastname  = parsed_name.dig(:lastname) if (contact.lastname.blank? || contact.lastname.casecmp?('friend')) && parsed_name.dig(:lastname).present?
                contact.sleep     = false
                contact.save

                contact.ggl_conversations.find_or_create_by(agent_id:, conversation_id:)

                unless contact.messages.find_by(from_phone: conversation_id, to_phone: '', account_sid: '', message_sid: message_id)
                  message = contact.messages.create({
                                                      account_sid: location_id,
                                                      automated:   false,
                                                      from_phone:  conversation_id,
                                                      message:     content,
                                                      message_sid: message_id,
                                                      msg_type:    'gglin',
                                                      status:      'received',
                                                      to_phone:    ''
                                                    })
                  image_result = ''

                  if media_url.present?

                    begin
                      contact_attachment = message.contact.contact_attachments.create!(remote_image_url: media_url)

                      message.attachments.create!(contact_attachment_id: contact_attachment.id) unless contact_attachment.nil?
                    rescue Cloudinary::CarrierWave::UploadError => e
                      image_result = 'Image file upload error'

                      e.set_backtrace(BC.new.clean(caller))

                      Appsignal.report_error(e) do |transaction|
                        # Only needed if it needs to be different or there's no active transaction from which to inherit it
                        Appsignal.set_action('Integrations::Google::MessagesController#endpoint')

                        # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                        Appsignal.add_params(params)

                        Appsignal.set_tags(
                          error_level: 'error',
                          error_code:  0
                        )
                        Appsignal.add_custom_data(
                          contact_attachment:,
                          media_url:,
                          message:,
                          file:               __FILE__,
                          line:               __LINE__
                        )
                      end
                    rescue ActiveRecord::RecordInvalid => e
                      image_result = e.inspect.include?('Image File size should be less than 5 MB') ? 'Image file too large - Max: 5 MB' : 'Image file upload error'

                      e.set_backtrace(BC.new.clean(caller))

                      Appsignal.report_error(e) do |transaction|
                        # Only needed if it needs to be different or there's no active transaction from which to inherit it
                        Appsignal.set_action('Integrations::Google::MessagesController#endpoint')

                        # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                        Appsignal.add_params(params)

                        Appsignal.set_tags(
                          error_level: 'error',
                          error_code:  0
                        )
                        Appsignal.add_custom_data(
                          contact_attachment:,
                          media_url:,
                          message:,
                          file:               __FILE__,
                          line:               __LINE__
                        )
                      end
                    rescue StandardError => e
                      image_result = 'Image file upload error'

                      e.set_backtrace(BC.new.clean(caller))

                      Appsignal.report_error(e) do |transaction|
                        # Only needed if it needs to be different or there's no active transaction from which to inherit it
                        Appsignal.set_action('Integrations::Google::MessagesController.endpoint')

                        # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                        Appsignal.add_params(params)

                        Appsignal.set_tags(
                          error_level: 'error',
                          error_code:  0
                        )
                        Appsignal.add_custom_data(
                          contact_attachment:,
                          media_url:,
                          message:,
                          file:               __FILE__,
                          line:               __LINE__
                        )
                      end
                    end
                  end

                  message.update(message: "#{message.message} (#{image_result})") if image_result.length.positive?

                  show_live_messenger = ShowLiveMessenger.new(message:)
                  show_live_messenger.queue_broadcast_active_contacts
                  show_live_messenger.queue_broadcast_message_thread_message

                  message.notify_users
                end
              end
            end
          elsif receipts.present?
            status_options = ['', 'sent', 'receipt_type_unspecified', 'delivered', 'read']

            receipts&.each do |receipt|
              if (message = Messages::Message.find_by(message_sid: receipt.dig(:message).to_s))
                message.update(status: status_options.index(receipt.dig(:receiptType).to_s.downcase) > status_options.index(message.status) ? receipt.dig(:receiptType).to_s.downcase : message.status)
                UserCable.new.broadcast message.contact.client, message.contact.user, { id: message.id, msg_status: message.status }
              end
            end
          end
        end

        respond_to do |format|
          format.json { render json: { status: 200, message: 'success' } }
          format.html { render plain: 'success', content_type: 'text/plain', layout: false, status: :ok }
        end
      end
      # sample User sending webhook
      # {
      #   "context": {
      #     "placeId": "",
      #     "userInfo": {
      #       "displayName": "Kevin Neubert",
      #       "userDeviceLocale": "en-US"
      #     },
      #     "resolvedLocale": "en"
      #   },
      #   "sendTime": "2022-10-11T23:03:03.318615Z",
      #   "conversationId": "72a88dca-58e8-4bb8-99bb-0302458fee1a",
      #   "customAgentId": "1",
      #   "requestId": "A489502D-239A-4747-B5FF-93FF86181865",
      #   "userStatus": {
      #     "isTyping": false,
      #     "createTime": "2022-10-11T23:03:03.005197Z"
      #   },
      #   "agent": "brands/85851e0e-8406-4812-8d15-53feecfa3b84/agents/bc69bbee-878a-4cda-a400-bec9311040e7",
      # }
      # sample message webhook
      # {
      #   "message": {
      #     "name": "conversations/72a88dca-58e8-4bb8-99bb-0302458fee1a/messages/0F00D216-5CC2-4E9C-AB46-BB9EA8CCF9FB",
      #     "text": "This is a test",
      #     "createTime": "2022-10-11T22:11:56.733266Z",
      #     "messageId": "0F00D216-5CC2-4E9C-AB46-BB9EA8CCF9FB"
      #   },
      #   "context": {
      #     "placeId": "",
      #     "userInfo": {
      #       "displayName": "Kevin Neubert",
      #       "userDeviceLocale": "en-US"
      #     }, "resolvedLocale": "en"
      #   },
      #   "sendTime": "2022-10-11T22:11:57.181854Z",
      #   "conversationId": "72a88dca-58e8-4bb8-99bb-0302458fee1a",
      #   "customAgentId": "1",
      #   "requestId": "0F00D216-5CC2-4E9C-AB46-BB9EA8CCF9FB",
      #   "agent": "brands/85851e0e-8406-4812-8d15-53feecfa3b84/agents/bc69bbee-878a-4cda-a400-bec9311040e7"
      # }

      # (GET) show main Google integration screen
      # /integrations/google/messages
      # integrations_google_messages_path
      # integrations_google_messages_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/google/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/google/messages/show' }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('google')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Google Messages Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end

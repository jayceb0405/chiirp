# frozen_string_literal: true

# app/controllers/messages/messages_controller.rb
module Messages
  class MessagesController < ApplicationController
    skip_before_action :verify_authenticity_token, only: %i[msg_callback msgin show_video]

    # clear unread messages for a Contact or all Contacts
    # /messages/messages/clear
    # messages_messages_clear_path
    # messages_messages_clear_url
    def clear_messages
      sanitized_params = params.permit(:contact_id, :message_id)

      if sanitized_params.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: sanitized_params[:contact_id].to_i))
        user = defined?(current_user) ? current_user : contact.user
        contact.clear_unread_messages(user)
      elsif sanitized_params.dig(:message_id).to_i.positive? && (message = Messages::Message.find_by(id: sanitized_params[:message_id].to_i))
        user = defined?(current_user) ? current_user : message.contact.user
        message.update(read_at: DateTime.current.to_s, read_at_user_id: user, updated_at: DateTime.current.to_s) if message.read_at.nil?

        Messages::UpdateUnreadMessageIndicatorsJob.perform_later(user_id: message.contact.user_id)
      elsif defined?(current_user)
        current_user.clear_unread_messages
      end

      render js: '', layout: false, status: :ok
    end

    # (POST) send text message
    # /messages
    # messages_path
    # messages_url
    # contact_messages_path(Contact)
    # contact_messages_url(Contact)
    # Optional Parameters:
    #   contacts_array:     (Array) Contact IDs for Contacts to send message to
    #   contact_id:         (Integer) Contact ID to send message to
    #   user_id:            (Integer) User ID who is sending message
    #   msg_delay:          (String) date/time when message should be sent out
    #   file_attachments:   (Array) JSON array of file data
    #     [
    #       { id: Integer, type: String, url: String },
    #       { id: Integer, type: String, url: String }
    #     ]
    #       type: "client", "user", "contact"
    #
    def create
      sanitized_params         = params.permit(:commit, :contact_id, :contacts_array, :from_phone, :msg_type, :to_phone, :user_id)
      sanitized_message_params = message_params
      @contact                 = Contact.find_by(id: sanitized_params.dig(:contact_id))

      @bubble = Messages::SendMessage.new(
        from_phone:             sanitized_params.dig(:from_phone),
        message:                sanitized_message_params.dig(:message),
        msg_delay:              sanitized_message_params.dig(:msg_delay),
        msg_type:               sanitized_params.dig(:msg_type),
        payment_request:        sanitized_message_params.dig(:payment_request),
        to_phone:               sanitized_params.dig(:to_phone),
        email_template_id:      sanitized_message_params.dig(:email_template_id),
        email_template_subject: sanitized_message_params.dig(:email_template_subject),
        email_template_yield:   sanitized_message_params.dig(:email_template_yield),
        email_template_cc:      sanitized_message_params.dig(:email_template_cc),
        email_template_bcc:     sanitized_message_params.dig(:email_template_bcc),
        file_attachments:       sanitized_message_params.dig(:file_attachments)
      ).send(
        contact_ids:        sanitized_params.dig(:contacts_array),
        contact_id:         sanitized_params.dig(:contact_id),
        file_attachments:   sanitized_message_params.dig(:file_attachments),
        user_id:            sanitized_params.dig(:user_id),
        voice_recording_id: sanitized_message_params.dig(:voice_recording_id)
      )

      cards  = %w[message_form_clear]
      cards << 'conversation_append' if (sanitized_message_params.dig(:message).present? || sanitized_message_params.dig(:file_attachments).present? || (@bubble[:msg_type] == 'emailout' && @bubble[:meta].present?)) && sanitized_message_params.dig(:msg_delay).empty?

      render partial: 'central/js/show', locals: { cards: }
    end

    # (GET) display unread Messages::Messages for User
    # /messages/messages/unread_messages_list
    # messages_header_unread_messages_list_path
    # messages_header_unread_messages_list_url
    def header_unread_messages_list
      render partial: 'layouts/looper/common/header/js/show', locals: { cards: %w[header_unread_messages_list] }
    end

    # (POST) receive a callback response after sending a text message
    # /message/msg_callback
    # message_msg_callback_path
    # message_msg_callback_url
    def msg_callback
      Messages::ProcessMessageCallbackJob.perform_later(
        **params.permit(:AccountSid, :ApiVersion, :at, :batch_id, :code, :From, :ErrorCode, :MessageSid, :MessageStatus, :operator_status_at, :recipient, :SmsSid, :SmsStatus, :status, :type, :To, _json: [:type, :to, :description, :from, :time, :errorCode, { message: [:id, :owner, :applicationId, :time, :segmentCount, :direction, :from, :text, :media, :tag, { to: [] }] }])
      )

      render xml: '<Response/>'
    end

    # (POST) receive a new text message
    # /message/msgin
    # message_msgin_path
    # message_msgin_url
    def msgin
      message = nil

      respond_to do |format|
        format.xml  { render xml: '<Response/>', layout: false, status: :ok }
        format.js   { render js: '', layout: false, status: :ok }
        format.html { render plain: 'Success', content_type: 'text/plain', layout: false, status: :ok }
      end

      result = SMS::Router.receive(params)

      # ignore blank messages
      return true if result[:success] && (result.dig(:message, :content)&.strip&.blank? && result.dig(:message, :media_array)&.compact_blank&.blank?)
      # ignore short codes
      return true if result[:success] && result.dig(:message, :from_phone)&.length != 12

      if result[:success]
        application_result = Messages::Message.apply_incoming_text_message_to_contact(result[:message])

        if application_result[:success]
          message = application_result[:message]
        elsif application_result[:error_message].present? && application_result[:client_id].positive? && (client = Client.find_by(id: application_result[:client_id]))
          Users::SendPushOrTextJob.perform_later(
            title:      'Message Received',
            content:    "#{application_result[:error_message]} Message: (#{params.dig('Body')}).",
            from_phone: I18n.t("tenant.#{Rails.env}.phone_number"),
            to_phone:   client.def_user.phone,
            user_id:    client.def_user_id
          )
        end
      elsif result[:error_message].present? && result[:client_id].positive? && (client = Client.find_by(id: result[:client_id]))
        Users::SendPushOrTextJob.perform_later(
          title:      'Message Received',
          content:    "#{result[:error_message]} Message: (#{params.dig('Body')}).",
          from_phone: I18n.t("tenant.#{Rails.env}.phone_number"),
          to_phone:   client.def_user.phone,
          user_id:    client.def_user_id
        )
      end

      if message

        # update phone number as "mobile"
        if (contact_phone = ContactPhone.find_by(contact_id: message.contact_id, phone: message.from_phone)) && contact_phone.label != 'mobile'
          contact_phone.update(label: 'mobile')
        end

        # parse message to update Tasks
        User.parse_text_to_complete_task(message)

        Messages::UpdateUnreadMessageIndicatorsJob.perform_later(user_id: message.contact.user_id)

        case message.message.strip.downcase
        when 'stop', 'stopall', 'unsubscribe'
          # Contact texted to stop all text messages
          message.contact.send_text(
            from_phone: message.to_phone,
            to_phone:   message.from_phone,
            content:    message.contact.client.dlc10_brand&.opt_out_message,
            automated:  true,
            msg_type:   'textoutother'
          )
          Contacts::Campaigns::StopJob.perform_now(contact_id: message.contact.id, campaign_id: 'all')
          message.contact.apply_stop_tag
          message.contact.ok2text_off
          message.contact.sleep_on
          message.contact.stop_aiagents
        when 'help', 'support'
          # Contact texted for help
          message.contact.send_text(
            from_phone: message.to_phone,
            to_phone:   message.from_phone,
            content:    message.contact.client.dlc10_brand&.help_message,
            automated:  true,
            msg_type:   'textoutother'
          )
        else

          # Contact texted to start all text messages
          if message.message.strip.casecmp?('start') || message.message.strip.casecmp?('join')
            message.contact.ok2text_on
            message.contact.sleep_off
            message.contact.remove_stop_tag

            message.contact.send_text(
              from_phone: message.to_phone,
              to_phone:   message.from_phone,
              content:    message.contact.client.dlc10_brand&.opt_in_message,
              automated:  true,
              msg_type:   'textoutother'
            )
          end

          # trigger Campaigns
          message.delay(
            run_at:              1.minute.from_now,
            priority:            DelayedJob.job_priority('trigger_campaigns'),
            queue:               DelayedJob.job_queue('trigger_campaigns'),
            user_id:             message.contact.user_id,
            contact_id:          message.contact_id,
            triggeraction_id:    0,
            contact_campaign_id: 0,
            group_process:       0,
            process:             'trigger_campaigns',
            data:                {}
          ).trigger_campaigns
        end

        # send Messages::Message to Five9
        # Integrations::FiveNine::Base.new(message.contact.client_id).delay(
        #   run_at:              1.minute.from_now,
        #   priority:            DelayedJob.job_priority('send_message_to_five9'),
        #   queue:               DelayedJob.job_queue('send_message_to_five9'),
        #   user_id:             message.contact.user_id,
        #   contact_id:          message.contact_id,
        #   triggeraction_id:    0,
        #   contact_campaign_id: 0,
        #   group_process:       0,
        #   process:             'send_message_to_five9',
        #   data:                { message: message.attributes }
        # ).send_message_to_five9(message)

        message.notify_users
      end

      true
    end

    # (GET) show a video
    # /vid/:short_code
    # messages_show_video_path(:short_code)
    # messages_show_video_url(:short_code)
    def show_video
      @contact_attachment = ContactAttachment.find_by(id: params[:short_code])

      respond_to do |format|
        format.js { render js: "window.location = '#{root_path}'" }
        format.html { render 'messages/show_video', layout: 'video' }
      end
    end

    private

    def message_params
      sanitized_params = params.require(:message).permit(:email_template_id, :email_template_subject, :email_template_yield, :email_template_cc, :email_template_bcc, :file_attachments, :message, :msg_delay, :payment_request, :voice_recording_id)

      sanitized_params[:email_template_id]      = sanitized_params.dig(:email_template_id).to_i
      sanitized_params[:email_template_subject] = sanitized_params.dig(:email_template_subject).to_s.strip
      sanitized_params[:email_template_yield]   = sanitized_params.dig(:email_template_yield).to_s.strip
      sanitized_params[:email_template_cc]      = sanitized_params.dig(:email_template_cc).to_s.strip
      sanitized_params[:email_template_bcc]     = sanitized_params.dig(:email_template_bcc).to_s.strip
      sanitized_params[:message]                = sanitized_params.dig(:message).to_s.strip
      sanitized_params[:msg_delay]              = sanitized_params.dig(:msg_delay).to_s
      sanitized_params[:payment_request]        = sanitized_params.dig(:payment_request).to_d
      sanitized_params[:voice_recording_id]     = sanitized_params.dig(:voice_recording_id).to_i.positive? ? sanitized_params.dig(:voice_recording_id).to_i : nil
      sanitized_params[:file_attachments]       = JSON.parse(sanitized_params.dig(:file_attachments) || '[]').collect(&:symbolize_keys)

      sanitized_params
    end
  end
end

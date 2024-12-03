# frozen_string_literal: true

# app/controllers/voice_in_controller.rb
class VoiceInController < ApplicationController
  class VoiceInControllerError < StandardError; end

  skip_before_action :verify_authenticity_token, only: %i[voice_in]

  # (POST) receive an incoming voice call
  # /twvoice/voicein
  # twvoice_voicein_path
  # twvoice_voicein_url
  def voice_in
    call_params    = Voice::Router.params_parse(params)
    contact_is_new = false

    if call_params[:from_phone].blank?
      JsonLog.info 'VoiceInController::VoiceIn', { unknown_caller: params }
      render_xml(Voice::Router.say(phone_vendor: call_params[:phone_vendor], content: 'We\'re sorry. The party you are trying to reach is not accepting calls from unknown callers.'))
    elsif (client_number = Twnumber.find_by(phonenumber: call_params[:to_phone]))

      if (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client_number.client_id, phones: { call_params[:from_phone] => 'voice' })) && contact.new_record?
        contact.city           = call_params[:from_city]
        contact.state          = call_params[:from_state]
        contact.zipcode        = call_params[:from_zip]
        contact.sleep          = false
        contact.last_contacted = Time.current
        contact_is_new         = true

        if (twnumberuser = client_number.twnumberusers.find_by(def_user: true))
          contact.user_id = twnumberuser.user_id
        end
      end

      if contact&.save

        if contact.block
          render_xml(Voice::Router.say(phone_vendor: call_params[:phone_vendor], content: 'We\'re sorry. The party you are trying to reach is unable to accept your call at this time.'))
          message_extra          = ' Blocked.'
          update_message_central = false
        else
          message_extra, update_message_central = case call_params[:phone_vendor]
                                                  when 'bandwidth'
                                                    render_xml_bandwidth(client_number, contact)
                                                  when 'twilio'
                                                    render_xml_twilio(client_number, contact, call_params)
                                                  end
        end

        # add call to Messages::Message
        message = contact.messages.find_or_create_by(message_sid: call_params[:call_id])
        message.update(
          message:     "In bound call from #{ActionController::Base.helpers.number_to_phone(call_params[:from_phone])} to #{ActionController::Base.helpers.number_to_phone(call_params[:to_phone])}.#{message_extra}",
          account_sid: call_params[:account_id],
          from_phone:  call_params[:from_phone],
          to_phone:    call_params[:to_phone],
          status:      'voicecallin',
          automated:   false,
          msg_type:    'voicein'
        )

        if update_message_central
          show_live_messenger = ShowLiveMessenger.new(message:)
          show_live_messenger.queue_broadcast_active_contacts
          show_live_messenger.queue_broadcast_message_thread_message
        end

        # find Campaigns to apply
        contact.delay(
          priority:   DelayedJob.job_priority('start_campaigns_on_incoming_call'),
          queue:      DelayedJob.job_queue('start_campaigns_on_incoming_call'),
          contact_id: contact.id,
          user_id:    contact.user_id,
          process:    'start_campaigns_on_incoming_call',
          data:       { client_phone_number: call_params[:to_phone], contact_is_new: }
        ).start_campaigns_on_incoming_call(
          client_phone_number: call_params[:to_phone],
          contact_is_new:
        )
      else
        # Contact.save failed
        render_xml(Voice::Router.say(phone_vendor: call_params[:phone_vendor], content: 'We\'re sorry. The party you are trying to reach is unable to accept your call at this time.'))

        if contact&.errors&.any? && contact&.errors&.full_messages&.map(&:downcase)&.join(' ')&.include?('maximum contacts')
          content = "Maximum Contacts! Call received from #{ActionController::Base.helpers.number_to_phone(call_params[:from_phone])}. Unable to create Contact."

          if (contact = client_number.client.contact)
            contact.delay(
              priority:   DelayedJob.job_priority('send_text_to_user'),
              queue:      DelayedJob.job_queue('send_text_to_user'),
              contact_id: contact.id,
              user_id:    contact.user_id,
              data:       { content: },
              process:    'send_text_to_user'
            ).send_text(
              content:,
              msg_type: 'textout'
            )
          else
            client_number.client.def_user.delay(
              priority: DelayedJob.job_priority('send_text_to_user'),
              queue:    DelayedJob.job_queue('send_text_to_user'),
              user_id:  client_number.client.def_user_id,
              process:  'send_text_to_user'
            ).send_text(
              from_phone: 'user_number',
              content:
            )
          end
        else
          error = VoiceInControllerError.new("VoiceInController::VoiceIn: Unable to create Contact with phone number #{call_params[:from_phone]}")
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('VoiceInController#voice_in')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(params)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              call_params:,
              client_number:,
              contact:,
              contact_errors: contact&.errors&.full_messages || 'None',
              contact_is_new:,
              file:           __FILE__,
              line:           __LINE__
            )
          end
        end
      end
    else
      JsonLog.info 'VoiceInController::VoiceIn', { message: 'Unable to find Client by phone number', phone_number: call_params[:to_phone] }
      render_xml(Voice::Router.say(phone_vendor: call_params[:phone_vendor], content: 'We\'re sorry. The party you are trying to reach is unknown.'))
    end
  end
  # example parameters from Bandwidth
  # {
  #   eventType:     'initiate',
  #   callId:        'c-693ef4a6-f3536426-ddc2-4751-b1b4-61385a4f1d40',
  #   from:          '+18022823191',
  #   to:            '+18022898010',
  #   privacy:       false,
  #   direction:     'inbound',
  #   applicationId: 'c7447ab1-2057-4413-b125-03504ed48e28',
  #   accountId:     '5007421',
  #   startTime:     '2024-08-05T20:44:25.894Z',
  #   eventTime:     '2024-08-05T20:44:25.896Z',
  #   callUrl:       'https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-693ef4a6-f3536426-ddc2-4751-b1b4-61385a4f1d40'
  # }

  private

  def phone_numbers_to_call(client_number, contact)
    users = contact.client.users.where(id: client_number.pass_routing).to_a
    pass_routing_ring_duration = client_number.pass_routing_ring_duration.to_i.positive? ? client_number.pass_routing_ring_duration.to_i : nil

    if client_number.pass_routing_method == 'chain'
      caller_ring_duration = if pass_routing_ring_duration
                               (users.count * pass_routing_ring_duration) + (client_number.pass_routing.include?('def_user') ? pass_routing_ring_duration : 0) + (client_number.pass_routing.include?('phone_number') ? pass_routing_ring_duration : 0)
                             else
                               users.sum { |u| u.ring_duration || 30 } + (client_number.pass_routing.include?('def_user') ? (contact.user.ring_duration || 30) : 0) + (client_number.pass_routing.include?('phone_number') ? 30 : 0)
                             end

      users = case client_number.pass_routing.first
              when 'def_user'
                [contact.user]
              when 'phone_number'
                [User.new(phone_in: client_number.pass_routing_phone_number, phone_in_with_action: false, ring_duration: pass_routing_ring_duration || 30)]
              else
                [User.find_by(client_id: client_number.client_id, id: client_number.pass_routing.first)]
              end
    else
      users << User.new(phone_in: client_number.pass_routing_phone_number, phone_in_with_action: false, ring_duration: pass_routing_ring_duration || 30) if client_number.pass_routing.include?('phone_number')
      users << contact.user if client_number.pass_routing.include?('def_user')
      caller_ring_duration = pass_routing_ring_duration || users.map { |u| u.ring_duration || 30 }.max
    end

    users.compact_blank!
    users.each { |u| u.ring_duration = pass_routing_ring_duration } if pass_routing_ring_duration
    announcement_url = client_number.announcement_recording&.url.to_s
    vm_content       = (client_number.vm_greeting_recording&.url || 'No one is available to take your call. Please record your message. When you are finished recording press the pound key or hang up.').to_s

    [users, caller_ring_duration, announcement_url, vm_content]
  end

  def render_xml(xml)
    # Rails.logger.info "xml response: #{xml.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    JsonLog.info ''
    render xml:
  end

  def render_xml_bandwidth(client_number, contact)
    sanitized_params       = params.permit(:accountId, :applicationId, :callId, :callUrl, :direction, :eventTime, :eventType, :from, :startTime, :to)
    message_extra          = ''
    update_message_central = false

    if client_number.incoming_call_routing == 'play' && client_number.announcement_recording&.url.present?
      # phone number defined to play a recording and hang up
      render_xml(Voice::Bandwidth.play(client_number.announcement_recording&.url.to_s))
      message_extra          = " Played recording (#{client_number.announcement_recording.recording_name}) and hung up."
      update_message_central = true
    elsif client_number.incoming_call_routing == 'play_vm' && client_number.announcement_recording&.url.present?
      # phone number defined to play a recording and wait for voicemail
      render_xml(Voice::Bandwidth.play_and_voicemail(recording_url: client_number.announcement_recording&.url.to_s, transcribe_url: voices_bandwidth_in_receive_voicemail_url(client_phone: sanitized_params.dig(:to).to_s.clean_phone(contact.client.primary_area_code))))
      message_extra = " Played recording (#{client_number.announcement_recording.recording_name}) and waited for voicemail."
    else
      # phone number defined to ring through to a User or specific phone
      users, caller_ring_duration, announcement_url, vm_greeting = phone_numbers_to_call(client_number, contact)

      if users.present?
        call_id    = sanitized_params.dig(:callId).to_s
        from_phone = sanitized_params.dig(:from).to_s.clean_phone(contact.client.primary_area_code)
        to_phone   = sanitized_params.dig(:to).to_s.clean_phone(contact.client.primary_area_code)

        users.each do |user|
          if user.phone_in.present?

            if user.phone_in_with_action
              # connect the call with User interaction
              Voice::Bandwidth.call(
                from_phone:     "+1#{from_phone}",
                to_phone:       "+1#{user.phone_in}",
                ring_duration:  user.ring_duration,
                parent_call_id: call_id,
                answer_url:     voices_bandwidth_in_user_answered_url(call_id, parent_from_phone: from_phone, client_phone: to_phone),
                disconnect_url: voices_bandwidth_in_disconnected_user_call_url(call_id, client_phone: to_phone)
              )
            else
              # connect the call without User interaction
              Voice::Bandwidth.call(
                from_phone:     "+1#{from_phone}",
                to_phone:       "+1#{user.phone_in}",
                ring_duration:  user.ring_duration,
                parent_call_id: call_id,
                answer_url:     voices_bandwidth_in_bridge_call_url(call_id, client_phone: to_phone),
                disconnect_url: voices_bandwidth_in_disconnected_user_call_url(call_id, client_phone: to_phone)
              )
            end

            unless user.new_record?
              # notify User
              Users::SendPushJob.perform_now(
                contact_id: contact.id,
                content:    "Call from: #{contact.fullname_or_phone}",
                title:      'Incoming Call',
                type:       'call',
                url:        central_url(contact_id: contact.id),
                user_id:    user.id
              )

              # pop up info alert with option to open Contact in Message Central
              if user.incoming_call_popup
                UserCable.new.broadcast user.client, user, { chiirp_alert: {
                  type:                'info',
                  title:               'Incoming Call',
                  body:                "Call from #{contact.fullname} (#{ActionController::Base.helpers.number_to_phone(from_phone)}).",
                  persistent:          true,
                  cancel_button_text:  'Close',
                  confirm_button_text: 'Go To Message Central',
                  url:                 central_url(contact_id: contact.id, domain: "#{contact.client.tenant}.com")
                } }
              end
            end
          elsif !user.new_record?
            # User does NOT have a phone number defined
            Users::SendPushOrTextJob.perform_later(
              title:   'Call Received',
              content: "From #{contact.fullname_or_phone}: Incoming Phone Number not defined. See User Settings.",
              url:     central_url(contact_id: contact.id),
              user_id: user.id
            )
          end
        end

        render_xml(Voice::Bandwidth.call_incoming_connect(
                     announcement_url:,
                     ring_duration:    caller_ring_duration,
                     vm_greeting:,
                     transcribe_url:   voices_bandwidth_in_receive_voicemail_url(client_phone: to_phone)
                   ))
      else
        # send to voicemail
        render_xml(Voice::Bandwidth.send_to_voicemail(
                     content:        'We are unavailable to take your call. Please leave a message after the beep. Press star to complete or simply hang up.',
                     transcribe_url: voices_bandwidth_in_receive_voicemail_url(client_phone: sanitized_params.dig(:to).to_s.clean_phone(contact.client.primary_area_code))
                   ))
      end
    end

    [message_extra, update_message_central]
  end

  def render_xml_twilio(client_number, contact, call_params)
    message_extra          = ''
    update_message_central = false

    if client_number.incoming_call_routing == 'play' && client_number.announcement_recording&.url.present?
      # phone number defined to play  a recording and hang up
      render_xml(Voice::TwilioVoice.play(client_number.announcement_recording&.url.to_s))
      message_extra          = " Played recording (#{client_number.announcement_recording.recording_name}) and hung up."
      update_message_central = true
    elsif client_number.incoming_call_routing == 'play_vm' && client_number.announcement_recording&.url.present?
      # phone number defined to play  a recording and wait for voicemail
      render_xml(Voice::TwilioVoice.play_and_voicemail(recording_url: client_number.announcement_recording&.url.to_s, transcribe_url: voices_twiliovoice_in_receive_voicemail_url(user_id: contact.user.id)).to_s)
      message_extra = " Played recording (#{client_number.announcement_recording.recording_name}) and waited for voicemail."
    else
      # phone number defined to ring through to a User or specific phone
      users, _caller_ring_duration, announcement_url, _vm_greeting = phone_numbers_to_call(client_number, contact)

      if users.present?
        from_phone = call_params.dig(:from_phone).to_s.clean_phone(contact.client.primary_area_code)
        user_array = []

        users.each do |user|
          if user.phone_in.present?
            user_array << {
              phone:         "+1#{user.phone_in}",
              ring_duration: user.ring_duration,
              action_url:    voices_twiliovoice_in_user_answered_url(call_params[:call_id], parent_from_phone: call_params[:from_phone])
            }

            unless user.new_record?
              # notify User
              Users::SendPushJob.perform_now(
                contact_id: contact.id,
                content:    "Call from: #{contact.fullname_or_phone}",
                title:      'Incoming Call',
                type:       'call',
                url:        central_url(contact_id: contact.id),
                user_id:    user.id
              )

              # pop up info alert with option to open Contact in Message Central
              if user.incoming_call_popup
                UserCable.new.broadcast user.client, user, { chiirp_alert: {
                  type:                'info',
                  title:               'Incoming Call',
                  body:                "Call from #{contact.fullname} (#{ActionController::Base.helpers.number_to_phone(from_phone)}).",
                  persistent:          true,
                  cancel_button_text:  'Close',
                  confirm_button_text: 'Go To Message Central',
                  url:                 central_url(contact_id: contact.id, domain: "#{contact.client.tenant}.com")
                } }
              end
            end
          elsif !user.new_record?
            # User does NOT have a phone number defined
            Users::SendPushOrTextJob.perform_later(
              title:   'Call Received',
              content: "From #{contact.fullname_or_phone}: Incoming Phone Number not defined. See User Settings.",
              url:     central_url(contact_id: contact.id),
              user_id: user.id
            )
          end
        end

        if user_array.present?
          render_xml(Voice::TwilioVoice.call_incoming_connect(
            announcement_url:,
            user_array:,
            complete_url:     voices_twiliovoice_in_call_complete_url(user_phone: user_array.first.dig(:phone).to_s),
            voicemail_url:    voices_twiliovoice_in_offer_voicemail_url(call_params[:call_id])
          ).to_s)
        else
          render_xml(Voice::TwilioVoice.send_to_voicemail(
            content:        'We are unavailable to take your call. Please leave a message after the beep. Press star to complete or simply hang up.',
            transcribe_url: voices_twiliovoice_in_receive_voicemail_url
          ).to_s)

          # User does NOT have a phone number
          Users::SendPushOrTextJob.perform_later(
            title:   'Call Received',
            content: "From #{contact.fullname_or_phone}: Incoming Phone Number not defined. See User Settings.",
            url:     central_url(contact_id: contact.id),
            user_id: contact.user_id
          )
        end
      else
        # send to voicemail
        render_xml(Voice::TwilioVoice.send_to_voicemail(
          content:        'We are unavailable to take your call. Please leave a message after the beep. Press star to complete or simply hang up.',
          transcribe_url: voices_twiliovoice_in_receive_voicemail_url
        ).to_s)

        # User does NOT have a phone number
        Users::SendPushOrTextJob.perform_later(
          title:   'Call Received',
          content: "From #{contact.fullname_or_phone}: Incoming Phone Number not defined. See User Settings.",
          url:     central_url(contact_id: contact.id),
          user_id: contact.user_id
        )
      end
    end

    [message_extra, update_message_central]
  end
end

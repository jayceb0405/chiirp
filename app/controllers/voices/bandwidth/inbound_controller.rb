# frozen_string_literal: true

# app/controllers/voices/bandwidth/inbound_controller.rb
module Voices
  module Bandwidth
    class InboundController < Voices::Bandwidth::VoiceController
      skip_before_action :verify_authenticity_token

      # (POST) Bridge another party (target call) onto the parent call
      # Respond with BXML
      # When the target call is bridged, any BXML being executed in it will be cancelled
      # /voices/bandwidth/in/bridge_call/:parent_call_id
      # voices_bandwidth_in_bridge_call_path(:parent_call_id)
      # voices_bandwidth_in_bridge_call_url(:parent_call_id)
      def bridge_call
        sanitized_params = params.permit(:accountId, :answerTime, :applicationId, :callId, :callUrl, :cause, :client_phone, :direction, :errorMessage, :eventTime, :eventType, :from, :parent_call_id, :startTime, :to)
        parent_call_id   = sanitized_params.dig(:parent_call_id).to_s
        to_phone         = sanitized_params.dig(:to).to_s.clean_phone

        if sanitized_params.dig(:cause)&.casecmp?('timeout') && sanitized_params.dig(:errorMessage)&.casecmp?('call was not answered')
          # call was not answered
          render_xml('<Response></Response>')
          update_message(message_sid: parent_call_id, unanswered_by_phone: to_phone)
        else
          # call was answered
          render_xml(Voice::Bandwidth.call_bridge(call_id: parent_call_id, contact_complete_url: voices_bandwidth_in_bridge_target_complete_url, user_complete_url: voices_bandwidth_in_bridge_complete_url(parent_call_id)))

          vr_client = Voice::RedisPool.new(parent_call_id)

          vr_client.call_ids.each do |call_id|
            Voice::Bandwidth.call_cancel(call_id) unless call_id == sanitized_params.dig(:callId).to_s
          end

          vr_client.call_ids_destroy

          update_message(message_sid: parent_call_id, answered_by_phone: to_phone)
        end
      end
      # example parameters
      # {
      #   eventType:      'answer',
      #   callId:         'c-52850c03-014298df-c661-4738-8dbf-9cbe09fb189f',
      #   from:           '+18022823191',
      #   to:             '+18023455136',
      #   privacy:        false,
      #   direction:      'outbound',
      #   applicationId:  'c7447ab1-2057-4413-b125-03504ed48e28',
      #   accountId:      '5007421',
      #   enqueuedTime:   '2024-08-05T20:44:26.776Z',
      #   startTime:      '2024-08-05T20:44:26.776Z',
      #   eventTime:      '2024-08-05T20:44:32.273Z',
      #   callUrl:        'https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-52850c03-014298df-c661-4738-8dbf-9cbe09fb189f',
      #   answerTime:     '2024-08-05T20:44:32.272Z',
      #   client_phone:   '8022898010',
      #   parent_call_id: 'c-693ef4a6-f3536426-ddc2-4751-b1b4-61385a4f1d40'
      # }

      # (POST) User left the bridged call
      # Respond with BXML - executed on the Contact call
      # If this webhook is sent, the Bridge Target Complete webhook is NOT sent
      # /voices/bandwidth/in/bridge_complete/:parent_call_id
      # voices_bandwidth_in_bridge_complete_path(:parent_call_id)
      # voices_bandwidth_in_bridge_complete_url(:parent_call_id)
      def bridge_complete
        sanitized_params = params.permit(:accountId, :answerTime, :applicationId, :callId, :callUrl, :direction, :eventTime, :eventType, :from, :parent_call_id, :startTime, :to)
        render_xml('<Response></Response>')

        update_message(
          message_sid:   sanitized_params.dig(:parent_call_id).to_s,
          call_status:   'completed',
          call_duration: Voice::Bandwidth.call_duration(sanitized_params.dig(:startTime), sanitized_params.dig(:eventTime))
        )

        vr_client = Voice::RedisPool.new(sanitized_params.dig(:parent_call_id).to_s)
        call_ids  = vr_client.call_ids

        return unless call_ids.include?(sanitized_params.dig(:callId).to_s)

        call_ids.delete(sanitized_params[:callId].to_s)
        # rubocop:disable Lint/UselessSetterCall
        vr_client.call_ids = call_ids
        # rubocop:enable Lint/UselessSetterCall
      end

      # (POST) Contact left the bridged call
      # Respond with BXML - executed on the Contact call
      # If this webhook is sent, the Bridge Complete webhook is NOT sent
      # /voices/bandwidth/in/bridge_target_complete
      # voices_bandwidth_in_bridge_target_complete_path
      # voices_bandwidth_in_bridge_target_complete_url
      def bridge_target_complete
        sanitized_params = params.permit(:applicationId, :accountId, :answerTime, :callId, :callUrl, :contact_campaign_id, :direction, :eventTime, :eventType, :from, :startTime, :to)

        update_message(
          message_sid: sanitized_params.dig(:callId),
          call_status: 'completed',
          call_duration: Voice::Bandwidth.call_duration(sanitized_params.dig(:startTime), sanitized_params.dig(:eventTime)), contact_campaign_id: sanitized_params.dig(:contact_campaign_id).to_i
        )

        render_xml('<Response></Response>')
      end
      # sample parameters
      # {
      #   eventType:     'bridgeTargetComplete',
      #   callId:        'c-693ef4a6-f3536426-ddc2-4751-b1b4-61385a4f1d40',
      #   from:          '+18022823191',
      #   to:            '+18022898010',
      #   privacy:       false,
      #   direction:     'inbound',
      #   applicationId: 'c7447ab1-2057-4413-b125-03504ed48e28',
      #   accountId:     '5007421',
      #   startTime:     '2024-08-05T20:44:25.894Z',
      #   eventTime:     '2024-08-05T20:44:37.557Z',
      #   callUrl:       'https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-693ef4a6-f3536426-ddc2-4751-b1b4-61385a4f1d40',
      #   answerTime:    '2024-08-05T20:44:28.681Z'
      # }

      # (POST) A call to a Contact ends, for any reason
      # Respond with 204, :no_content
      # Causes: hangup, busy, timeout, cancel, rejected, callback-error, invalid-bxml, application-error, account-limit, node-capacity-exceeded, error, unknown
      # /voices/bandwidth/in/disconnectedcalls/:parent_call_id
      # voices_bandwidth_in_disconnected_contact_call_path(:parent_call_id)
      # voices_bandwidth_in_disconnected_contact_call_url(:parent_call_id)
      def disconnected_contact_call
        sanitized_params = params.permit(:accountId, :answerTime, :applicationId, :callId, :callUrl, :cause, :client_phone, :direction, :endTime, :errorMessage, :eventTime, :eventType, :from, :parent_call_id, :startTime, :to)
        to_phone         = sanitized_params.dig(:to).to_s.clean_phone

        if sanitized_params.dig(:cause)&.casecmp?('timeout') && sanitized_params.dig(:errorMessage)&.casecmp?('call was not answered')
          # call was not answered
          update_message(message_sid: sanitized_params.dig(:parent_call_id).to_s, unanswered_by_phone: to_phone)
        end

        head :no_content
      end

      # (POST) A call to a User ends, for any reason
      # Respond with 204, :no_content
      # Causes: hangup, busy, timeout, cancel, rejected, callback-error, invalid-bxml, application-error, account-limit, node-capacity-exceeded, error, unknown
      # /voices/bandwidth/in/disconnectedcallu/:parent_call_id
      # voices_bandwidth_in_disconnected_user_call_path(:parent_call_id)
      # voices_bandwidth_in_disconnected_user_call_url(:parent_call_id)
      def disconnected_user_call
        sanitized_params = params.permit(:accountId, :answerTime, :applicationId, :callId, :callUrl, :cause, :client_phone, :direction, :endTime, :errorMessage, :eventTime, :eventType, :from, :parent_call_id, :startTime, :to)
        to_phone         = sanitized_params.dig(:to).to_s.clean_phone

        if sanitized_params.dig(:cause)&.casecmp?('timeout') && sanitized_params.dig(:errorMessage)&.casecmp?('call was not answered')
          # call was not answered
          call_user_no_answer_xml(sanitized_params)
          update_message(message_sid: sanitized_params.dig(:parent_call_id).to_s, unanswered_by_phone: to_phone)
        end

        vr_client = Voice::RedisPool.new(sanitized_params.dig(:parent_call_id).to_s)
        call_ids  = vr_client.call_ids

        if call_ids.include?(sanitized_params.dig(:callId).to_s)
          call_ids.delete(sanitized_params[:callId].to_s)
          vr_client.call_ids = call_ids
        end

        head :no_content
      end
      # sample parameters
      # {
      #   eventType:      'disconnect',
      #   callId:         'c-52850c03-014298df-c661-4738-8dbf-9cbe09fb189f',
      #   from:           '+18022823191',
      #   to:             '+18023455136',
      #   privacy:        false,
      #   direction:      'outbound',
      #   applicationId:  'c7447ab1-2057-4413-b125-03504ed48e28',
      #   accountId:      '5007421',
      #   enqueuedTime:   '2024-08-05T20:44:26.776Z',
      #   startTime:      '2024-08-05T20:44:26.776Z',
      #   eventTime:      '2024-08-05T20:44:37.543Z',
      #   callUrl:        'https://voice.bandwidth.com/api/v2/accounts/5007421/calls/c-52850c03-014298df-c661-4738-8dbf-9cbe09fb189f',
      #   answerTime:     '2024-08-05T20:44:32.272Z',
      #   endTime:        '2024-08-05T20:44:37.543Z',
      #   cause:          'hangup',
      #   client_phone:   '8022898010',
      #   parent_call_id: 'c-693ef4a6-f3536426-ddc2-4751-b1b4-61385a4f1d40'
      # }

      # (POST) Prompt Contact for voicemail.
      # /voices/bandwidth/in/offer_voicemail/:parent_call_id
      # voices_bandwidth_in_offer_voicemail_path(:parent_call_id)
      # voices_bandwidth_in_offer_voicemail_url(:parent_call_id)
      def offer_voicemail
        sanitized_params = params.permit(:accountId, :answerTime, :applicationId, :callId, :callUrl, :client_phone, :direction, :eventTime, :eventType, :from, :parent_call_id, :startTime, :to)
        to_phone         = sanitized_params.dig(:to).to_s.clean_phone

        if to_phone.present? && (twnumber = Twnumber.find_by(phonenumber: to_phone)) && twnumber.vm_greeting_recording&.url.present?
          render_xml(Voice::Bandwidth.call_accept_voicemail(voice_recording_url: twnumber.vm_greeting_recording&.url, transcribe_url: voices_bandwidth_in_receive_voicemail_url(client_phone: to_phone)))
        else
          render_xml(Voice::Bandwidth.call_accept_voicemail(content: 'No one is available to take your call.', transcribe_url: voices_bandwidth_in_receive_voicemail_url(client_phone: to_phone)))
        end

        if (contact = Messages::Message.find_by(message_sid: sanitized_params.dig(:callId).to_s)&.contact)
          Contacts::Campaigns::StartOnMissedCallJob.perform_later(
            client_id:           contact.client_id,
            client_phone_number: to_phone,
            contact_id:          contact.id,
            user_id:             contact.user_id
          )
        end

        update_message(
          message_sid:      sanitized_params.dig(:callId).to_s,
          call_status:      'completed',
          call_duration:    Voice::Bandwidth.call_duration(sanitized_params.dig(:startTime), sanitized_params.dig(:eventTime)),
          refresh_messages: true
        )
      end

      # (POST) Receive voicemail & transcript.
      # /voices/bandwidth/in/receive_voicemail
      # voices_bandwidth_in_receive_voicemail_path
      # voices_bandwidth_in_receive_voicemail_url
      def receive_voicemail
        sanitized_params = params.permit(:accountId, :applicationId, :callId, :callUrl, :client_phone, :direction, :duration, :endTime, :eventTime, :eventType, :fileFormat, :from, :mediaUrl, :recordingId, :startTime, :to, transcription: %i[completeTime id status url])

        if sanitized_params.dig(:transcription, :url).present? && sanitized_params.dig(:mediaUrl).present?
          # transcribed message was received

          if (client_number = Twnumber.find_by(phonenumber: sanitized_params.dig(:client_phone).to_s.clean_phone))
            transcription_text = Voice::Bandwidth.transcription_text(transcription_text_url: sanitized_params.dig(:transcription, :url).to_s)
            recording_url      = Voice::Bandwidth.recording_transfer(client: client_number.client, recording_url: sanitized_params.dig(:mediaUrl).to_s)

            update_message(
              message_sid:        sanitized_params.dig(:callId),
              transcription_text:,
              recording_url:
            )
          else
            JsonLog.info 'Voices::Bandwidth::InboundController.receive_voicemail', { phone_number: sanitized_params.dig(:client_phone).to_s.clean_phone }
          end
        end

        render plain: '', content_type: 'text/plain', layout: false, status: :ok
      end

      # (POST) User answered the call.
      # /voices/bandwidth/in/user_answered/:parent_call_id
      # voices_bandwidth_in_user_answered_path(:parent_call_id)
      # voices_bandwidth_in_user_answered_url(:parent_call_id)
      def user_answered
        sanitized_params  = params.permit(:accountId, :answerTime, :applicationId, :callId, :callUrl, :client_phone, :direction, :eventTime, :eventType, :from, :parent_call_id, :startTime, :to)
        client_phone      = sanitized_params.dig(:client_phone).to_s.clean_phone
        parent_call_id    = sanitized_params.dig(:parent_call_id).to_s
        parent_from_phone = sanitized_params.dig(:from).to_s

        if (client_number = Twnumber.find_by(phonenumber: client_phone))

          if (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client_number.client_id, phones: { parent_from_phone => 'voice' }))
            contact.save

            render_xml(Voice::Bandwidth.call_screen(
                         content:      "You have an incoming call from #{contact.fullname_or_phone}.",
                         callback_url: voices_bandwidth_in_user_responded_url(parent_call_id, client_phone)
                       ))
          else
            Users::SendPushOrTextJob.perform_later(
              title:   'Call Received',
              content: "From #{ActionController::Base.helpers.number_to_phone(parent_from_phone)}: Unable to locate Contact.",
              url:     root_url,
              user_id: client_number.client.def_user_id
            )

            render_xml(Voice::Bandwidth.hangup(content: 'Sorry, no one answered.'))
          end
        else
          JsonLog.info 'Voices::Bandwidth::InboundController.user_answered', { unknown_client_phone_number: client_phone }
          render_xml(Voice::Bandwidth.hangup)
        end
      end

      # (POST) User responded to prompt to accept/reject call
      # /voices/bandwidth/in/user_answered/:parent_call_id/:client_phone
      # voices_bandwidth_in_user_responded_path(:parent_call_id, :client_phone)
      # voices_bandwidth_in_user_responded_url(:parent_call_id, :client_phone)
      def user_responded
        sanitized_params = params.permit(:accountId, :answerTime, :applicationId, :callId, :callUrl, :client_phone, :digits, :direction, :eventTime, :eventType, :from, :parent_call_id, :startTime, :terminatingDigit, :to)
        parent_call_id   = sanitized_params.dig(:parent_call_id).to_s
        to_phone         = sanitized_params.dig(:to).to_s.clean_phone

        if sanitized_params.dig(:digits).to_s == '*'
          render_xml(call_user_no_answer_xml(sanitized_params))
          update_message(message_sid: parent_call_id, declined_by_phone: to_phone)
        else
          render_xml(Voice::Bandwidth.say(
                       content:              'Connecting you now.',
                       call_id:              parent_call_id,
                       contact_complete_url: voices_bandwidth_in_bridge_target_complete_url,
                       user_complete_url:    voices_bandwidth_in_bridge_complete_url(parent_call_id)
                     ))

          vr_client = Voice::RedisPool.new(sanitized_params.dig(:parent_call_id).to_s)

          vr_client.call_ids.each do |call_id|
            Voice::Bandwidth.call_cancel(call_id) unless call_id == sanitized_params.dig(:callId).to_s
          end

          vr_client.call_ids_destroy

          update_message(message_sid: parent_call_id, answered_by_phone: to_phone)
        end
      end

      # (POST)
      # /voices/bandwidth/in/voicemail_answered/:parent_call_id
      # voices_bandwidth_in_voicemail_answered_path(/:parent_call_id)
      # voices_bandwidth_in_voicemail_answered_url(/:parent_call_id)
      def voicemail_answered
        sanitized_params = params.permit(:machineDetectionResult, :parent_call_id)

        Voice::Bandwidth.call_redirect(call_id: sanitized_params.dig(:parent_call_id).to_s, redirect_url: voices_bandwidth_in_offer_voicemail_url(sanitized_params.dig(:parent_call_id).to_s)) if sanitized_params.dig(:machineDetectionResult, :value).to_s == 'answering-machine'

        # render xml: Voice::Bandwidth.hangup
      end

      private

      def call_user_no_answer_xml(sanitized_params)
        client_phone      = sanitized_params.dig(:client_phone).to_s.clean_phone
        from_phone        = sanitized_params.dig(:from).to_s.clean_phone
        parent_call_id    = sanitized_params.dig(:parent_call_id).to_s
        to_phone          = sanitized_params.dig(:to).to_s.clean_phone
        response          = '<Response></Response>'

        next_phone = if (twnumber = Twnumber.find_by(phonenumber: client_phone)) && twnumber.pass_routing_method == 'chain'
                       twnumber.next_pass_routing_phone_number(to_phone)
                     else
                       ''
                     end

        if next_phone.present? && (user = User.where(client_id: twnumber&.client_id, id: twnumber&.pass_routing).find_by('data @> ?', { phone_in: next_phone }.to_json))

          if user.phone_in_with_action
            # connect the call with User interaction
            Voice::Bandwidth.call(
              from_phone:     sanitized_params.dig(:from).to_s.clean_phone,
              parent_call_id:,
              ring_duration:  user.ring_duration,
              to_phone:       next_phone,
              answer_url:     voices_bandwidth_in_user_answered_url(parent_call_id, parent_from_phone: from_phone, client_phone:),
              disconnect_url: voices_bandwidth_in_disconnected_user_call_url(parent_call_id, client_phone:)
            )
          else
            # connect the call without User interaction
            Voice::Bandwidth.call(
              from_phone:     sanitized_params.dig(:from).to_s.clean_phone,
              parent_call_id:,
              ring_duration:  user.ring_duration,
              to_phone:       next_phone,
              answer_url:     voices_bandwidth_in_bridge_call_url(parent_call_id, client_phone:),
              disconnect_url: voices_bandwidth_in_disconnected_user_call_url(parent_call_id, client_phone:)
            )
          end
        elsif next_phone.present?
          Voice::Bandwidth.call(
            from_phone:     sanitized_params.dig(:from).to_s.clean_phone,
            parent_call_id:,
            ring_duration:  20,
            to_phone:       next_phone,
            answer_url:     voices_bandwidth_in_bridge_call_url(parent_call_id, client_phone:),
            disconnect_url: voices_bandwidth_in_disconnected_user_call_url(parent_call_id, client_phone:)
          )
        elsif twnumber&.pass_routing_method.to_s == 'chain'

          response = Voice::Bandwidth.hangup(
            call_id:      parent_call_id,
            redirect_url: voices_bandwidth_in_offer_voicemail_url(parent_call_id, user_id: sanitized_params.dig(:user_id).to_i)
          )
        else
          vr_client = Voice::RedisPool.new(sanitized_params.dig(:parent_call_id).to_s)
          call_ids  = vr_client.call_ids

          response = if call_ids.length == 1 && sanitized_params.dig(:callId).to_s == call_ids.first
                       Voice::Bandwidth.hangup(
                         call_id:      parent_call_id,
                         redirect_url: voices_bandwidth_in_offer_voicemail_url(parent_call_id, user_id: sanitized_params.dig(:user_id).to_i)
                       )
                     else
                       Voice::Bandwidth.hangup
                     end
        end

        response
      end

      def render_xml(xml)
        # Rails.logger.info "xml response: #{xml.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        JsonLog.info 'Voices::Bandwidth::InboundController.'
        render xml:, status: :ok
      end
    end
  end
end

# frozen_string_literal: true

# Twilio incoming call w/intervention processes...
#   VoiceInController#voice_in
#   VoiceInController#voice_in_screen_call
#   VoiceInController#voice_in_user_screen
#   VoiceInController#voice_in_voicemail

# Twilio incoming call w/o intervention processes...
#   VoiceInController#voice_in

# app/controllers/voices/twiliovoice/inbound_controller.rb
module Voices
  module Twiliovoice
    # Support for voices/twilio/in endpoints used with Chiirp
    class InboundController < Voices::Twiliovoice::VoiceController
      class TwiliovoiceInboundController < StandardError; end

      skip_before_action :verify_authenticity_token, only: %i[bridge_complete call_complete offer_voicemail receive_voicemail user_answered user_responded]
      before_action :authenticate_user!, except: %i[bridge_complete call_complete offer_voicemail receive_voicemail user_answered user_responded]

      # /voices/twiliovoice/in/bridge_complete/:parent_call_id
      # voices_twiliovoice_in_bridge_complete_path(:parent_call_id)
      # voices_twiliovoice_in_bridge_complete_url(:parent_call_id)
      def bridge_complete
        call_params      = Voice::TwilioVoice.params_parse(params)
        call_status      = (call_params[:call_status] || 'completed').to_s
        user_call_status = (call_params[:user_call_status] || 'completed').to_s

        if call_status == 'in-progress' && user_call_status == 'no-answer'
          # the call to User was NOT successful, then record a voicemail
          send_to_voicemail(client_phone)

          update_message(
            message_sid:         call_params[:call_id],
            call_status:         user_call_status,
            unanswered_by_phone: params.dig(:user_phone).to_s
          )
        else
          unless call_params[:number_pressed].to_s == 'hangup'
            update_message(
              message_sid:         call_params[:call_id],
              call_status:         'completed',
              call_duration:       call_params[:call_duration],
              contact_campaign_id: params.dig(:contact_campaign_id).to_i,
              answered_by_phone:   params.dig(:user_phone).to_s
            )
          end

          respond_to do |format|
            format.xml  { render xml: '' }
            format.html { render plain: '', content_type: 'text/plain', layout: false, status: :ok }
          end
        end
      end

      # (POST) call is complete
      # /voices/twiliovoice/in/call_complete
      # voices_twiliovoice_in_call_complete_path(contact_phone: String)
      # voices_twiliovoice_in_call_complete_url(contact_phone: String)
      def call_complete
        sanitized_params = params.permit(:AccountSid, :ApiVersion, :Called, :Caller, :CallSid, :CallStatus, :DialBridged, :DialCallDuration, :DialCallSid, :DialCallStatus, :Direction, :From, :To, :user_phone)
        client_phone     = sanitized_params.dig(:Called).to_s.clean_phone
        contact_phone    = sanitized_params.dig(:Caller).to_s.clean_phone
        user_phone       = sanitized_params.dig(:user_phone).to_s.clean_phone

        case sanitized_params.dig(:DialCallStatus).to_s.downcase
        when 'no-answer'
          render_xml(call_next_phone_xml(client_phone, contact_phone, user_phone, sanitized_params.dig(:CallSid).to_s))
        when 'completed'
          render_xml(Voice::TwilioVoice.hangup)
          update_message(
            message_sid:   sanitized_params.dig(:CallSid).to_s,
            call_status:   'completed',
            call_duration: sanitized_params.dig(:DialCallDuration).to_i
          )
        end
      end

      # (POST)
      # /voices/twiliovoice/in/offer_voicemail/:parent_call_id
      # voices_twiliovoice_in_offer_voicemail_path(:parent_call_id)
      # voices_twiliovoice_in_offer_voicemail_url(:parent_call_id)
      def offer_voicemail
        sanitized_params = params.permit(:AccountSid, :ApiVersion, :Called, :Caller, :CallSid, :CallStatus, :Direction, :parent_call_id, :From, :To)
        call_status      = (sanitized_params.dig(:CallStatus) || 'completed').to_s
        client_phone     = sanitized_params.dig(:Called).to_s.clean_phone

        if call_status == 'completed'
          render_xml(Voice::TwilioVoice.hangup)
          update_message(
            message_sid: sanitized_params.dig(:CallSid).to_s,
            call_status: 'completed'
          )
        else
          # the call to User was NOT successful, then record a voicemail
          render_xml(send_to_voicemail(client_phone))
        end
      end

      # /voices/twiliovoice/in/receive_voicemail
      # voices_twiliovoice_in_receive_voicemail__path
      # voices_twiliovoice_in_receive_voicemail__url
      def receive_voicemail
        sanitized_params = params.permit(:AccountSid, :ApiVersion, :Called, :Caller, :CallSid, :CallStatus, :Direction, :ForwardedFrom, :From, :RecordingSid, :RecordingUrl, :To, :TranscriptionType, :TranscriptionSid, :TranscriptionStatus, :TranscriptionText, :TranscriptionUrl)
        user_phone       = sanitized_params.dig(:To).to_s.clean_phone

        if sanitized_params.dig(:TranscriptionText).present? && sanitized_params.dig(:RecordingUrl).present? && (client = Client.joins(:twnumbers).find_by(twnumbers: { phonenumber: user_phone }))
          # transcribed message was received
          update_message(
            message_sid:        sanitized_params[:CallSid],
            transcription_text: sanitized_params[:TranscriptionText].to_s,
            recording_url:      Voice::TwilioVoice.recording_transfer(client:, recording_url: sanitized_params[:RecordingUrl].to_s)
          )
        end

        render plain: '', content_type: 'text/plain', layout: false, status: :ok
      end

      # (POST) callback received after an inbound call is connected with a User
      # /voices/twiliovoice/in/user_answered/:parent_call_id
      # voices_twiliovoice_in_user_answered_path(:parent_call_id)
      # voices_twiliovoice_in_user_answered_url(:parent_call_id)
      # CallStatus = initiated, ringing, answered, completed, no-answer
      def user_answered
        sanitized_params = params.permit(:AccountSid, :ApiVersion, :Called, :CalledVia, :Caller, :CallSid, :CallStatus, :Direction, :ForwardedFrom, :From, :ParentCallSid, :To)
        client_phone     = sanitized_params.dig(:ForwardedFrom).to_s.clean_phone
        contact_phone    = sanitized_params.dig(:From).to_s.clean_phone
        user_phone       = sanitized_params.dig(:To).to_s.clean_phone

        if (twnumber = Twnumber.find_by(phonenumber: client_phone))

          if (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: twnumber.client_id, phones: { contact_phone => 'voice' }))
            contact.save

            case sanitized_params.dig(:CallStatus).to_s.downcase
            when 'no-answer'
              render_xml(call_next_phone_xml(client_phone, contact_phone, user_phone, sanitized_params.dig(:ParentCallSid).to_s))
            when 'answered', 'in-progress'

              if twnumber.pass_routing_method != 'multi' && (user = User.where(client_id: twnumber&.client_id, id: twnumber&.pass_routing).find_by('data @> ?', { phone_in: user_phone }.to_json)) && user.phone_in_with_action
                render_xml(Voice::TwilioVoice.call_screen(
                  content:      "You have an incoming call from #{contact.fullname_or_phone}.",
                  callback_url: voices_twiliovoice_in_user_responded_url(sanitized_params.dig(:ParentCallSid).to_s, (contact_phone || 'unused'), user_id: contact.user_id)
                ).to_s)
              else
                render_xml('<Response></Response>')
                update_message(message_sid: sanitized_params.dig(:ParentCallSid).to_s, answered_by_phone: user_phone, refresh_messages: true)
              end
            else
              render_xml('<Response></Response>')
            end
          else
            Users::SendPushOrTextJob.perform_later(
              title:   'Call Received',
              content: "From #{ActionController::Base.helpers.number_to_phone(ActionController::Base.helpers.number_to_phone(contact_phone))}: Unable to locate Contact.",
              url:     root_url,
              user_id: twnumber.client.def_user_id
            )

            render_xml(Voice::TwilioVoice.hangup(content: 'Sorry, no one answered.').to_s)
          end
        else
          JsonLog.info 'Voices::TwilioVoice::InboundController.user_answered', { unknown_client_phone_number: client_phone }
          render_xml(Voice::TwilioVoice.hangup)
        end
      end

      # (POST)
      # /voices/twiliovoice/in/user_responded/:parent_call_id/:parent_from_phone
      # voices_twiliovoice_in_user_responded_path(:parent_call_id, :parent_from_phone)
      # voices_twiliovoice_in_user_responded_url(:parent_call_id, :parent_from_phone)
      def user_responded
        sanitized_params = params.permit(:AccountSid, :ApiVersion, :Called, :CalledVia, :CallSid, :CallStatus, :Digits, :Direction, :FinishedOnKey, :ForwardedFrom, :From, :msg, :ParentCallSid, :To)
        client_phone     = sanitized_params.dig(:ForwardedFrom).to_s.clean_phone
        contact_phone    = sanitized_params.dig(:From).to_s.clean_phone
        user_phone       = sanitized_params.dig(:To).to_s.clean_phone

        if sanitized_params.dig(:Digits).to_s == '*'
          result = call_next_phone_xml(client_phone, contact_phone, user_phone, sanitized_params.dig(:ParentCallSid).to_s)

          Voice::TwilioVoice.call_update(call_id: sanitized_params.dig(:ParentCallSid).to_s, xml: result) unless result == '<Response></Response>'

          Voice::TwilioVoice.hangup
          update_message(message_sid: sanitized_params.dig(:ParentCallSid).to_s, declined_by_phone: user_phone)
        else
          render_xml(Voice::TwilioVoice.say(
            content: 'Connecting you now.',
            call_id: sanitized_params[:ParentCallSid]
          ).to_s)

          update_message(message_sid: sanitized_params.dig(:ParentCallSid).to_s, answered_by_phone: user_phone)
        end
      end

      private

      def call_next_phone_xml(client_phone, contact_phone, user_phone, call_id)
        response = ''

        if (twnumber = Twnumber.find_by(phonenumber: client_phone))

          if twnumber.pass_routing_method == 'chain'
            next_phone = twnumber.next_pass_routing_phone_number(user_phone)

            if next_phone.present? && (user = User.where(client_id: twnumber&.client_id, id: twnumber&.pass_routing).find_by('data @> ?', { phone_in: next_phone }.to_json))
              response = Voice::TwilioVoice.call_incoming_connect(
                user_array:    [{
                  phone:         "+1#{user.phone_in}",
                  ring_duration: user.ring_duration,
                  action_url:    voices_twiliovoice_in_user_answered_url(call_id, parent_from_phone: "+1#{contact_phone}")
                }],
                complete_url:  voices_twiliovoice_in_call_complete_url(user_phone: "+1#{next_phone}"),
                voicemail_url: voices_twiliovoice_in_offer_voicemail_url(call_id)
              )
            elsif next_phone.present?
              response = Voice::TwilioVoice.call_incoming_connect(
                user_array:    [{
                  phone:         next_phone,
                  ring_duration: 20,
                  action_url:    voices_twiliovoice_in_user_answered_url(call_id, parent_from_phone: "+1#{contact_phone}")
                }],
                complete_url:  voices_twiliovoice_in_call_complete_url(user_phone: "+1#{next_phone}"),
                voicemail_url: voices_twiliovoice_in_offer_voicemail_url(call_id)
              )
            else
              response = '<Response></Response>'
              Voice::TwilioVoice.call_update(call_id:, xml: send_to_voicemail(client_phone))

              if (contact = Messages::Message.find_by(message_sid: call_id)&.contact)
                Contacts::Campaigns::StartOnMissedCallJob.perform_later(
                  client_id:           contact.client_id,
                  client_phone_number: client_phone,
                  contact_id:          contact.id,
                  user_id:             contact.user_id
                )
              end
            end
          else
            response = '<Response></Response>'
            Voice::TwilioVoice.call_update(call_id:, xml: send_to_voicemail(client_phone))

            if (contact = Messages::Message.find_by(message_sid: call_id)&.contact)
              Contacts::Campaigns::StartOnMissedCallJob.perform_later(
                client_id:           contact.client_id,
                client_phone_number: client_phone,
                contact_id:          contact.id,
                user_id:             contact.user_id
              )
            end
          end
        else
          error = TwiliovoiceInboundController.new("Unknown Client Phone Number: #{client_phone}")
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Voices::Twiliovoice::InboundController#call_next_phone_xml')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(params)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              call_id:,
              client_phone:,
              contact_phone:,
              response:,
              user_phone:,
              file:          __FILE__,
              line:          __LINE__
            )
          end

          response = Voice::TwilioVoice.hangup
        end

        response
      end

      def missed_call(call_id, client_phone)
        return if call_id.blank? || client_phone.blank?

        if (contact = Contact.joins(:messages).find_by(messages: { message_sid: call_id }))
          Contacts::Campaigns::StartOnMissedCallJob.perform_later(
            client_id:           contact.client_id,
            client_phone_number: client_phone,
            contact_id:          contact.id,
            user_id:             contact.user_id
          )
        end

        update_message(message_sid: sanitized_params.dig(:CallSid), refresh_messages: true)
      end

      def render_xml(xml)
        # Rails.logger.info "xml response: #{xml.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        render xml:, status: :ok
      end

      def send_to_voicemail(client_phone = '')
        if client_phone.present? && (twnumber = Twnumber.find_by(phonenumber: client_phone)) && twnumber.vm_greeting_recording&.url.present?
          Voice::TwilioVoice.send_to_voicemail(voice_recording_url: twnumber.vm_greeting_recording.url, transcribe_url: voices_twiliovoice_in_receive_voicemail_url).to_s
        else
          Voice::TwilioVoice.send_to_voicemail(content: 'No one is available to take your call.', transcribe_url: voices_twiliovoice_in_receive_voicemail_url).to_s
        end
      end
    end
  end
end

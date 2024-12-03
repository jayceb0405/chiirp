# frozen_string_literal: true

# app/controllers/voices/twiliovoice/outbound_controller.rb
module Voices
  module Twiliovoice
    class OutboundController < Voices::Twiliovoice::VoiceController
      skip_before_action :verify_authenticity_token, only: %i[user_answered]
      before_action :authenticate_user!, except: %i[user_answered]

      def user_answered
        # (POST)
        # /voices/twiliovoice/out/user_answered
        # voices_twiliovoice_out_user_answered_path
        # voices_twiliovoice_out_user_answered_url
        call_params = Voice::TwilioVoice.params_parse(params)
        contact_id  = params.dig(:contact_id).to_i

        if contact_id.positive? && (contact = Contact.find_by(id: contact_id))
          contact_campaign_id = params.dig(:contact_campaign_id).to_i
          triggeraction_id    = params.dig(:triggeraction_id).to_i

          if call_params[:callback_source].blank?
            # TWIML callback request
            # connect the call in progress to the Contacts phone

            if ['', 'human', 'unknown'].include?(call_params[:answered_by])
              create_message(contact:, call_params:)
              render xml: connect_user_to_contact(contact:, call_params:, contact_campaign_id:, triggeraction_id:)
            else
              render xml: Voice::TwilioVoice.hangup

              connect_user_to_contact_campaign(contact:, contact_campaign_id:, triggeraction_id:)
            end

          elsif call_params[:callback_source] == 'call-progress-events'
            # callbacks with various CallStatus (initiated, in-progress, ringing, answered, completed)
            # completed event status (busy, canceled, completed, failed, no-answer)

            if call_params[:call_status] == 'completed'

              # it takes 2 calls to connect a User with a Contact
              Voice::TwilioVoice.get_child_calls(parent_sid: call_params[:call_id]).each do |call_child|
                call_params[:call_duration] += call_child[:call_duration]
              end

              update_message(
                message_sid:         call_params[:call_id],
                connected_to_phone:  call_params.dig(:to_phone).to_s,
                call_status:         call_params[:call_status],
                call_duration:       call_params[:call_duration],
                contact_campaign_id:,
                triggeraction_id:
              )
            elsif (message = contact.messages.find_by(message_sid: call_params[:call_id]))

              message.update(status: call_params[:call_status])
            end

            respond_to do |format|
              format.js   { render js: '', layout: false, status: :ok }
              format.html { render plain: '', content_type: 'text/plain', layout: false, status: :ok }
            end
          end
        else

          respond_to do |format|
            format.js   { render js: '', layout: false, status: :ok }
            format.html { render plain: '', content_type: 'text/plain', layout: false, status: :ok }
          end
        end
      end

      private

      def connect_user_to_contact(args = {})
        contact     = args.dig(:contact)
        call_params = args.dig(:call_params)

        if contact.is_a?(Contact) && call_params.is_a?(Hash)
          contact_campaign_id = args.dig(:contact_campaign_id).to_i

          if (contact_campaign = contact.contact_campaigns.find_by(id: contact_campaign_id))
            triggeraction_id = args.dig(:triggeraction_id).to_i
            to_phones        = contact.org_users(users_orgs: contact_campaign.data.dig(:triggeractions, triggeraction_id, :to_users_orgs), purpose: 'voice', default_to_all_users_in_org_position: false)

            response = if to_phones.present?
                         Voice::TwilioVoice.call_outgoing_connect(
                           from_phone: call_params[:from_phone],
                           to_phone:   to_phones[0][0],
                           content:    "Please hold while we connect to #{to_phones[0][1]}."
                         )
                       else
                         Voice::TwilioVoice.hangup
                       end

            if contact_campaign.data[:triggeractions][triggeraction_id][:stop_on_connection]
              Contacts::Campaigns::StopJob.perform_now(
                campaign_id:         'this',
                contact_campaign_id:,
                contact_id:          contact.id
              )
            end
          else
            to_phone = params.dig(:contact_phone).to_s.present? ? params[:contact_phone].to_s : contact.primary_phone&.phone.to_s
            response = Voice::TwilioVoice.call_outgoing_connect(
              from_phone: call_params[:from_phone],
              to_phone:,
              content:    "Please hold while we connect to #{contact.fullname}."
            )
          end
        else
          response = Voice::TwilioVoice.hangup
        end

        response
      end

      def connect_user_to_contact_campaign(args = {})
        contact             = args.dig(:contact)
        contact_campaign_id = args.dig(:contact_campaign_id).to_i
        triggeraction_id    = args.dig(:triggeraction_id).to_i

        return unless contact.is_a?(Contact)
        return unless (contact_campaign = contact.contact_campaigns.find_by(id: contact_campaign_id))
        return unless contact_campaign.data.dig(:triggeractions, triggeraction_id, :current_retry_count).to_i < contact_campaign.data.dig(:triggeractions, triggeraction_id, :retry_count).to_i

        data = {
          users_orgs:          contact_campaign.data[:triggeractions][triggeraction_id][:from_users_orgs],
          from_phone:          contact_campaign.data[:triggeractions][triggeraction_id][:from_phone],
          machine_detection:   contact_campaign.data[:triggeractions][triggeraction_id][:machine_detection],
          contact_campaign_id:,
          triggeraction_id:
        }
        contact.delay(
          run_at:              Time.current + contact_campaign.data[:triggeractions][triggeraction_id][:retry_interval].minutes,
          priority:            DelayedJob.job_priority(contact_campaign.data[:triggeractions][triggeraction_id][:process]),
          queue:               DelayedJob.job_queue(contact_campaign.data[:triggeractions][triggeraction_id][:process]),
          user_id:             contact.user_id,
          contact_id:          contact.id,
          triggeraction_id:,
          contact_campaign_id:,
          group_process:       0,
          process:             contact_campaign.data[:triggeractions][triggeraction_id][:process],
          data:
        ).call(data)

        contact_campaign.data[:triggeractions][triggeraction_id][:current_retry_count] += 1
        contact_campaign.save
      end

      def create_message(args = {})
        contact     = args.dig(:contact)
        call_params = args.dig(:call_params)
        response    = nil

        if contact.is_a?(Contact) && call_params.is_a?(Hash)
          to_phone = contact.primary_phone&.phone.to_s
          response = contact.messages.create(
            account_sid: call_params[:account_id],
            automated:   false,
            from_city:   call_params[:to_city],
            from_phone:  call_params[:from_phone],
            from_state:  call_params[:to_state],
            from_zip:    call_params[:to_zip],
            message:     "Out bound call from #{ActionController::Base.helpers.number_to_phone(call_params[:from_phone])} to #{ActionController::Base.helpers.number_to_phone(to_phone)}.",
            message_sid: call_params[:call_id],
            msg_type:    'voiceout',
            read_at:     Time.current,
            status:      call_params[:call_status],
            to_phone:
          )
        end

        response
      end
    end
  end
end

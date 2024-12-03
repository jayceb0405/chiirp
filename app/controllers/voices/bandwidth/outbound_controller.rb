# frozen_string_literal: true

# Bandwidth outgoing call processes...
#   CentralController#call_contact
#   Voice::Bandwidth::OutboundController#user_answered
#   Voice::Bandwidth::OutboundController#contact_answered
#   Voice::Bandwidth::OutboundController#bridge_complete

# app/controllers/voices/bandwidth/outbound_controller.rb
module Voices
  module Bandwidth
    class OutboundController < Voices::Bandwidth::VoiceController
      skip_before_action :verify_authenticity_token

      # (POST)
      # /voices/bandwidth/out/bridge_complete/:parent_call_id
      # voices_bandwidth_out_bridge_complete_path(:parent_call_id)
      # voices_bandwidth_out_bridge_complete_url(:parent_call_id)
      def bridge_complete
        call_params = Voice::Bandwidth.params_parse(params)
        update_message(message_sid: call_params[:parent_call_id], connected_to_phone: params.dig(:user_phone), call_status: 'completed', call_duration: call_params[:call_duration], contact_campaign_id: params.dig(:contact_campaign_id).to_i)

        render_xml('<Response></Response>')
      end

      # (POST)
      # /voices/bandwidth/out/bridge_target_complete
      # voices_bandwidth_out_bridge_target_complete_path
      # voices_bandwidth_out_bridge_target_complete_url
      def bridge_target_complete
        call_params = Voice::Bandwidth.params_parse(params)
        update_message(message_sid: call_params[:call_id], connected_to_phone: call_params[:to_phone], call_status: 'completed', call_duration: call_params[:call_duration], contact_campaign_id: params.dig(:contact_campaign_id).to_i)

        render_xml('<Response></Response>')
      end

      # (POST)
      # /voices/bandwidth/out/contact_answered/:parent_call_id
      # voices_bandwidth_out_contact_answered_path(:parent_call_id)
      # voices_bandwidth_out_contact_answered_url(:parent_call_id)
      def contact_answered
        call_params = Voice::Bandwidth.params_parse(params)
        render_xml(Voice::Bandwidth.call_bridge(call_id: call_params[:parent_call_id], contact_complete_url: voices_bandwidth_out_bridge_target_complete_url, user_complete_url: voices_bandwidth_out_bridge_complete_url(call_params[:parent_call_id], user_phone: params.dig(:user_phone).to_s)))
      end

      # (POST)
      # /voices/bandwidth/out/disconnected_call/:parent_call_id
      # voices_bandwidth_out_disconnected_call_path(:parent_call_id)
      # voices_bandwidth_out_disconnected_call_url(:parent_call_id)
      def disconnected_call
        call_params       = Voice::Bandwidth.params_parse(params)
        santitized_params = params.permit(:cause, :errorMessage)
        cause             = santitized_params.dig(:cause).to_s
        error_message     = santitized_params.dig(:errorMessage).to_s.downcase

        if cause == 'timeout' && error_message == 'call was not answered'
          # call was not answered
          update_message(message_sid: call_params[:parent_call_id], unanswered_by_phone: call_params[:to_phone])
        end

        render_xml('<Response></Response>')
      end

      # (POST)
      # /voices/bandwidth/out/user_answered
      # voices_bandwidth_out_user_answered_path
      # voices_bandwidth_out_user_answered_url
      def user_answered
        call_params      = Voice::Bandwidth.params_parse(params)
        sanitized_params = params.permit(:contact_campaign_id, :contact_id, :triggeraction_id)
        contact_id       = sanitized_params.dig(:contact_id).to_i

        if call_params[:event_type] == 'answer' && contact_id.positive? && (contact = Contact.find_by(id: contact_id))
          contact_campaign_id = sanitized_params.dig(:contact_campaign_id).to_i
          triggeraction_id    = sanitized_params.dig(:triggeraction_id).to_i

          create_message(contact:, call_params:)
          render_xml(call_contact(contact:, call_params:, contact_campaign_id:, triggeraction_id:))
        else

          respond_to do |format|
            format.js   { render js: '', layout: false, status: :ok }
            format.html { render plain: '', content_type: 'text/plain', layout: false, status: :ok }
          end
        end
      end

      private

      def call_contact(args = {})
        contact     = args.dig(:contact)
        call_params = args.dig(:call_params)

        if contact.is_a?(Contact) && call_params.is_a?(Hash)
          contact_campaign_id = args.dig(:contact_campaign_id).to_i

          if (contact_campaign = contact.contact_campaigns.find_by(id: contact_campaign_id))
            triggeraction_id = args.dig(:triggeraction_id).to_i
            to_phones        = contact.org_users(users_orgs: contact_campaign.data.dig(:triggeractions, triggeraction_id, :to_users_orgs), purpose: 'voice', default_to_all_users_in_org_position: false)

            response = if to_phones.present?
                         Voice::Bandwidth.call_outgoing_connect(
                           from_phone:     call_params[:from_phone],
                           to_phone:       to_phones[0][0],
                           content:        "Please hold while we connect to #{to_phones[0][1]}.",
                           ring_duration:  60,
                           callback_url:   voices_bandwidth_out_contact_answered_url(call_params[:call_id], user_phone: to_phones[0][0]),
                           disconnect_url: voices_bandwidth_out_disconnected_call_url(call_params[:call_id])
                         )
                       else
                         Voice::Bandwidth.hangup
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
            response = Voice::Bandwidth.call_outgoing_connect(
              from_phone:     call_params[:from_phone],
              to_phone:,
              content:        "Please hold while we connect to #{contact.fullname}.",
              ring_duration:  60,
              callback_url:   voices_bandwidth_out_contact_answered_url(call_params[:call_id], user_phone: call_params[:to_phone].to_s),
              disconnect_url: voices_bandwidth_out_disconnected_call_url(call_params[:call_id])
            )
          end
        else
          response = Voice::Bandwidth.hangup
        end

        response
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

      def render_xml(xml)
        # Rails.logger.info "xml response: #{xml.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        render xml:
      end
    end
  end
end

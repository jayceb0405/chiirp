# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/send_message_as_note.rb
module Integrations
  module Servicetitan
    module V2
      class SendMessageAsNote < ApplicationJob
        # Integrations::Servicetitan::V2::SendMessageAsNote.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Servicetitan::V2::SendMessageAsNote.set(wait_until: 1.day.from_now, priority: 0).perform_later()

        def initialize(**args)
          super

          @process = (args.dig(:process).presence || 'servicetitan_send_note').to_s
        end

        # perform the ActiveJob
        #   (opt) contact_campaign_id: (Integer),
        #   (opt) contact_id:          (Integer),
        #   (opt) data:                (Hash),
        #   (opt) group_process:       (Integer),
        #   (req) message_id:          (Integer)
        #   (opt) process:             (String),
        #   (opt) triggeraction_id:    (Integer),
        #   (opt) user_id:             (Integer)
        def perform(**args)
          super

          return unless args.dig(:message_id).to_i.positive? && (message = Messages::Message.find_by(id: args[:message_id])) &&
                        (client_api_integration = ClientApiIntegration.find_by(client_id: message.contact.client_id, target: 'servicetitan', name: '')) &&
                        ((message.msg_type.casecmp?('textin') && client_api_integration.notes.dig('textin')) ||
                        (message.msg_type.casecmp?('textoutaiagent') && client_api_integration.notes.dig('textout_aiagent')) ||
                        (message.msg_type.casecmp?('textout') && message.automated && client_api_integration.notes.dig('textout_auto')) ||
                        (message.msg_type.casecmp?('textout') && !message.automated && client_api_integration.notes.dig('textout_manual'))) &&
                        (st_customer_id = message.contact.ext_references.find_by(target: 'servicetitan')&.ext_id)

          Integration::Servicetitan::V2::Base.new(client_api_integration).send_note(st_customer_id:, content: "#{message.msg_type.casecmp?('textin') ? 'Rcvd' : 'Sent'}: #{message.message}")
        end

        def reschedule_at(current_time, attempts)
          if @reschedule_secs.positive?
            current_time + @reschedule_secs.seconds
          else
            current_time + ProcessError::Backoff.full_jitter(base: 5, cap: 10, retries: attempts).minutes
          end
        end
      end
    end
  end
end

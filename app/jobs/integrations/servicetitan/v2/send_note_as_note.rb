# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/send_note_as_note.rb
module Integrations
  module Servicetitan
    module V2
      class SendNoteAsNote < ApplicationJob
        # Integrations::Servicetitan::V2::SendNoteAsNote.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Servicetitan::V2::SendNoteAsNote.set(wait_until: 1.day.from_now, priority: 0).perform_later()

        def initialize(**args)
          super

          @process          = (args.dig(:process).presence || 'servicetitan_send_note').to_s
          @reschedule_secs  = 0
        end

        # perform the ActiveJob
        #   (opt) contact_campaign_id: (Integer),
        #   (opt) contact_id:          (Integer),
        #   (req) contact_note_id:     (Integer)
        #   (opt) data:                (Hash),
        #   (opt) group_process:       (Integer),
        #   (opt) process:             (String),
        #   (opt) triggeraction_id:    (Integer),
        #   (opt) user_id:             (Integer)
        def perform(**args)
          super

          return unless args.dig(:contact_note_id).to_i.positive? && (contact_note = Contacts::Note.find_by(id: args[:contact_note_id])) &&
                        (client_api_integration = ClientApiIntegration.find_by(client_id: contact_note.contact.client_id, target: 'servicetitan', name: '')) &&
                        client_api_integration.notes.dig('push_notes') &&
                        (st_customer_id = contact_note.contact.ext_references.find_by(target: 'servicetitan')&.ext_id)

          Integration::Servicetitan::V2::Base.new(client_api_integration).send_note(st_customer_id:, content: contact_note.note)
        end
      end
    end
  end
end

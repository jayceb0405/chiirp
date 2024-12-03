# frozen_string_literal: true

# app/jobs/contacts/ok2text_off_job.rb
module Contacts
  class Ok2textOffJob < ApplicationJob
    # set ok2text on for a Contact
    # Contacts::Ok2textOffJob.perform_now()
    # Contacts::Ok2textOffJob.set(wait_until: 1.day.from_now).perform_later()
    # Contacts::Ok2textOffJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'ok2text_off').to_s
    end

    # perform the ActiveJob
    #   (req) contact_id: (Integer)
    def perform(**args)
      super

      return unless (contact = Contact.find_by(id: args.dig(:contact_id).to_i))

      contact.update(ok2text: 0)
    end
  end
end

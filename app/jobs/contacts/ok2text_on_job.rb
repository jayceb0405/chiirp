# frozen_string_literal: true

# app/jobs/contacts/ok2text_on_job.rb
module Contacts
  class Ok2textOnJob < ApplicationJob
    # set ok2text on for a Contact
    # Contacts::Ok2textOnJob.perform_now()
    # Contacts::Ok2textOnJob.set(wait_until: 1.day.from_now).perform_later()
    # Contacts::Ok2textOnJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'ok2text_on').to_s
    end

    # perform the ActiveJob
    #   (req) contact_id: (Integer)
    def perform(**args)
      super

      return unless (contact = Contact.find_by(id: args.dig(:contact_id).to_i))

      contact.update(ok2text: 1)
    end
  end
end

# frozen_string_literal: true

# app/jobs/contacts/sleep_job.rb
module Contacts
  class SleepJob < ApplicationJob
    # sleep a Contact
    # Contacts::SleepJob.perform_now()
    # Contacts::SleepJob.set(wait_until: 1.day.from_now).perform_later()
    # Contacts::SleepJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'contact_sleep').to_s
    end

    # perform the ActiveJob
    #   (req) contact_id: (Integer)
    def perform(**args)
      super

      return unless (contact = Contact.find_by(id: args.dig(:contact_id).to_i))

      contact.update(sleep: true)
    end
  end
end

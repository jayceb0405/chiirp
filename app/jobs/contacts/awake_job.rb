# frozen_string_literal: true

# app/jobs/contacts/awake_job.rb
module Contacts
  class AwakeJob < ApplicationJob
    # sleep a Contact
    # Contacts::AwakeJob.perform_now()
    # Contacts::AwakeJob.set(wait_until: 1.day.from_now).perform_later()
    # Contacts::AwakeJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'contact_awake').to_s
    end

    # perform the ActiveJob
    #   (req) contact_id: (Integer)
    def perform(**args)
      super

      return unless (contact = Contact.find_by(id: args.dig(:contact_id).to_i))

      contact.update(sleep: false)
    end
  end
end

# frozen_string_literal: true

# app/jobs/contacts/delete_job.rb
module Contacts
  class DeleteJob < ApplicationJob
    # destroy a Contact
    # Contacts::DeleteJob.perform_now()
    # Contacts::DeleteJob.set(wait_until: 1.day.from_now).perform_later()
    # Contacts::DeleteJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'contact_delete').to_s
    end

    # perform the ActiveJob
    #   (req) contact_id: (Integer)
    def perform(**args)
      super

      return unless (contact = Contact.find_by(id: args.dig(:contact_id).to_i))

      contact.destroy
    end
  end
end

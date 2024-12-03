# frozen_string_literal: true

# app/jobs/contacts/assign_user_job.rb
module Contacts
  class AssignUserJob < ApplicationJob
    # set ok2text on for a Contact
    # Contacts::AssignUserJob.perform_now()
    # Contacts::AssignUserJob.set(wait_until: 1.day.from_now).perform_later()
    # Contacts::AssignUserJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'assign_user').to_s
    end

    # perform the ActiveJob
    #   (req) contact_id:  (Integer)
    #   (req) new_user_id: (Integer)
    def perform(**args)
      super

      return unless (contact = Contact.find_by(id: args.dig(:contact_id).to_i))

      contact.assign_user(args.dig(:new_user_id))
    end
  end
end

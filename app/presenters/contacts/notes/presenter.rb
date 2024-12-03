# frozen_string_literal: true

# app/presenters/contacts/notes/presenter.rb
module Contacts
  module Notes
    class Presenter < BasePresenter
      attr_reader :client, :contact, :user

      # presenter = Contacts::Notes::Presenter.new()
      #   (req) contact: (Contact)
      def initialize(args = {})
        super

        @contact_notes = nil
      end

      def contact_notes
        @contact_notes ||= self.contact.notes.includes(:user).order('created_at DESC')
      end

      def contact_notes?
        self.contact_notes.any?
      end
    end
  end
end

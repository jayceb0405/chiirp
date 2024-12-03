# frozen_string_literal: true

# app/presenters/messages/email/presenter.rb
module Messages
  class Email
    class Presenter < BasePresenter
      attr_accessor :contact, :email_template_id, :email_template_yield, :file_attachments, :email_template_subject, :cc_email, :bcc_email, :from_email, :payment_request, :show_ok2email, :show_calendar, :show_submit

      # Messages::Email::Presenter.new()
      def initialize(args = {})
        super

        self.bcc_email              = args.dig(:bcc_email) || ''
        self.cc_email               = args.dig(:cc_email) || ''
        self.client                 = args.dig(:client)
        self.contact                = args.dig(:contact)
        self.email_template_id      = args.dig(:email_template_id) || 0
        self.email_template_yield   = args.dig(:email_template_yield) || ''
        self.email_template_subject = args.dig(:email_template_subject) || ''
        self.file_attachments       = args.dig(:file_attachments) || []
        self.from_email             = args.dig(:from_email) || ''
        self.payment_request        = args.dig(:payment_request) || nil

        self.show_ok2email          = args.include?(:show_ok2email) ? args[:show_ok2email] : true
        self.show_calendar          = args.include?(:show_calendar) ? args[:show_calendar] : true
        self.show_submit            = args.include?(:show_submit) ? args[:show_submit] : true
      end
    end
  end
end

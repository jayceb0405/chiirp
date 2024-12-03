# frozen_string_literal: true

# app/jobs/integrations/jobnimbus/v1/imports/contact_job.rb
module Integrations
  module Jobnimbus
    module V1
      module Imports
        class ContactJob < ApplicationJob
          # import Contacts from JobNimbus clients
          # step 3 / import the JobNimbus client
          # Integrations::Jobnimbus::V1::Imports::ContactJob.perform_now()
          # Integrations::Jobnimbus::V1::Imports::ContactJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Jobnimbus::V1::Imports::ContactJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'jobnimbus_import_contact').to_s
          end

          # perform the ActiveJob
          #   (req) client_id:  (Integer)
          #   (req) user_id:    (Integer)
          #   (req) jn_contact: (Hash)
          #
          #   (opt) new_contacts_only: (Boolean / default: false)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? &&
                          args.dig(:jn_contact).is_a?(Hash) && args[:jn_contact].present? &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'jobnimbus', name: '')) &&
                          (jn_model = Integration::Jobnimbus::V1::Base.new(client_api_integration)) && jn_model.valid_credentials?

            phones = {}
            phones[args.dig(:jn_contact, :mobile_phone).to_s] = 'mobile' if args.dig(:jn_contact, :mobile_phone).present?
            phones[args.dig(:jn_contact, :home_phone).to_s]   = 'home' if args.dig(:jn_contact, :home_phone).present?
            phones[args.dig(:jn_contact, :work_phone).to_s]   = 'work' if args.dig(:jn_contact, :work_phone).present?
            phones[args.dig(:jn_contact, :fax_number).to_s]   = 'fax' if args.dig(:jn_contact, :fax_number).present?

            if (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client_api_integration.client_id, phones:, emails: [args.dig(:jn_contact, :email).to_s], ext_refs: { 'jobnimbus' => args.dig(:jn_contact, :jnid).to_s })) && (contact.new_record? || !args.dig(:new_contacts_only).to_bool)
              contact.update(
                firstname: args.dig(:jn_contact, :first_name).to_s,
                lastname:  args.dig(:jn_contact, :last_name).to_s,
                address1:  args.dig(:jn_contact, :address_line1).to_s,
                address2:  args.dig(:jn_contact, :address_line2).to_s,
                city:      args.dig(:jn_contact, :city).to_s,
                state:     args.dig(:jn_contact, :state_text).to_s,
                zipcode:   args.dig(:jn_contact, :zip).to_s
              )

              jn_model.sales_rep_update(
                id:    args.dig(:jn_contact, :sales_rep),
                name:  args.dig(:jn_contact, :sales_rep_name),
                email: args.dig(:jn_contact, :sales_rep_email)
              )
            end

            CableBroadcaster.new.contacts_import_remaining(client: client_api_integration.client_id, count: jn_model.contact_imports_remaining_string)
          end
        end
      end
    end
  end
end

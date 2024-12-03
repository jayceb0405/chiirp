# frozen_string_literal: true

# app/jobs/integrations/jobber/v20231115/imports/contact_job.rb
module Integrations
  module Jobber
    module V20231115
      module Imports
        class ContactJob < ApplicationJob
          # import Contacts from Jobber clients
          # step 3 / import the Jobber client
          # Integrations::Jobber::V20231115::Imports::ContactJob.perform_now()
          # Integrations::Jobber::V20231115::Imports::ContactJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Jobber::V20231115::Imports::ContactJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'jobber_import_contact').to_s
          end

          # perform the ActiveJob
          #   (req) actions:          (Hash)
          #     see Integrations::Jobber::V20231115::Imports::ContactActionsJob
          #   (req) client_id:        (Integer)
          #   (req) jobber_client_id: (String)
          #   (req) user_id:          (Integer)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? &&
                          args.dig(:actions).is_a?(Hash) && args.dig(:jobber_client_id).to_s.present? &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'jobber', name: '')) &&
                          (jb_model = Integration::Jobber::V20231115::Base.new(client_api_integration)) && jb_model.valid_credentials? &&
                          (jb_client = Integrations::JobBer::V20231115::Base.new(client_api_integration.credentials))

            jobber_client = jb_client.client(args[:jobber_client_id])
            contact       = nil

            if jb_client.success? && ((!args.dig(:actions, :eq_0, :import).to_bool && !args.dig(:actions, :below_0, :import).to_bool && !args.dig(:actions, :above_0, :import).to_bool) ||
               (args.dig(:actions, :eq_0, :import).to_bool && jobber_client.dig(:balance).to_d.zero?) ||
               (args.dig(:actions, :below_0, :import).to_bool && jobber_client.dig(:balance).to_d.negative?) ||
               (args.dig(:actions, :above_0, :import).to_bool && jobber_client.dig(:balance).to_d.positive?))

              phones    = {}
              ok_2_text = 0
              jobber_client.dig(:phones).each do |p|
                phones[p.dig(:number).to_s.tr('^0-9', '')] = p.dig(:description).to_s if p.dig(:number).to_s.tr('^0-9', '').length == 10
                ok_2_text = 1 if p.dig(:smsAllowed).to_bool
              end

              return false unless (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: args[:client_id], phones:, emails: jobber_client.dig(:emails)&.first&.dig(:address).to_s, ext_refs: { 'jobber' => args[:jobber_client_id] }))

              contact.lastname       = (jobber_client.dig(:lastName) || contact.lastname).to_s
              contact.firstname      = (jobber_client.dig(:firstName) || contact.firstname).to_s
              contact.companyname    = (jobber_client.dig(:companyName) || contact.companyname).to_s
              contact.address1       = (jobber_client.dig(:billingAddress, :street1) || contact.address1).to_s
              contact.address2       = (jobber_client.dig(:billingAddress, :street2) || contact.address2).to_s
              contact.city           = (jobber_client.dig(:billingAddress, :city) || contact.city).to_s
              contact.state          = (jobber_client.dig(:billingAddress, :province) || contact.state).to_s
              contact.zipcode        = (jobber_client.dig(:billingAddress, :postalCode) || contact.zipcode).to_s
              contact.ok2text        = ok_2_text if contact.ok2text.to_i.positive?
              contact.ok2email       = 1
              contact.save

              if contact.valid?

                jobber_client.dig(:tags, :nodes).each do |t|
                  if t.dig(:label).present?
                    Contacts::Tags::ApplyByNameJob.perform_now(
                      contact_id: contact.id,
                      tag_name:   t[:label]
                    )
                  end
                end

                Integrations::Jobber::V20231115::Imports::ContactActionsJob.perform_now(
                  account_balance: jobber_client.dig(:balance).to_d,
                  actions:         args[:actions],
                  client_id:       args[:client_id],
                  contact_id:      contact.id,
                  user_id:         args[:user_id]
                )
              else
                JsonLog.info 'Integration::Jobber::V20231115::ImportContacts.import_contact', { errors: contact.errors.full_messages, contact_phones: contact.contact_phones }, client_id: args[:client_id], contact_id: contact.id
              end
            end

            jb_model.import_contacts_remaining_update(args[:user_id])
          end
        end
      end
    end
  end
end

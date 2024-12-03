# frozen_string_literal: true

# app/models/integration/sendjim/v3/sendjim.rb
module Integration
  module Sendjim
    module V3
      # SendJim data processing
      class Sendjim < ApplicationRecord
        # return a string that may be used to inform the User how many more SendJim contacts are remaining in the queue to be imported
        # Integration::Sendjim::V3::Sendjim.contact_imports_remaining_string(Integer)
        # (req) user_id: (Integer)
        def self.contact_imports_remaining_string(user_id)
          delayed_jobs            = DelayedJob.where(user_id:, process: %w[sendjim_import_contact sendjim_import_contacts sendjim_import_contacts_block]).group(:process).count
          import_contacts         = delayed_jobs.dig('sendjim_import_contacts').to_i
          import_contacts_block   = delayed_jobs.dig('sendjim_import_contacts_block').to_i * 50
          import_contact          = delayed_jobs.dig('sendjim_import_contact').to_i

          if import_contacts.positive? && (import_contacts_block + import_contact).zero?
            'Contact Imports Queued'
          elsif (import_contacts + import_contacts_block + import_contact).to_i > 1
            "Contacts awaiting import: #{import_contacts_block.positive? ? '< ' : ''}#{import_contacts_block + import_contact}"
          else
            ''
          end
        end

        def self.credentials_exist?(client_api_integration)
          client_api_integration&.token.present?
        end

        # import a SendJim contact
        # Integration::Sendjim::V3::Sendjim.import_contact()
        # (req) client_id:         (Integer)
        # (opt) new_contacts_only: (Boolean)
        # (req) sendjim_contact:   (Hash)
        # (req) user_id:           (Integer)
        def self.import_contact(args = {})
          return if args.dig(:client_id).to_i.zero?

          self.update_contact_imports_remaining_count(Client.find_by(id: args[:client_id].to_i), User.find_by(client_id: args[:client_id].to_i, id: args.dig(:user_id)))

          return unless args.dig(:sendjim_contact).is_a?(Hash)

          phones = {}
          phones[args[:sendjim_contact][:PhoneNumber].to_s] = 'mobile' if args[:sendjim_contact].dig(:PhoneNumber).to_s.present?
          emails = []
          emails << args[:sendjim_contact][:Email].to_s if args[:sendjim_contact].dig(:Email).to_s.present?

          return unless (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: args[:client_id].to_i, phones:, emails:, ext_refs: { 'sendjim' => args[:sendjim_contact].dig(:ContactID).to_i })) && (contact.new_record? || !args.dig(:new_contacts_only).to_bool)

          contact.update(
            companyname: args[:sendjim_contact].dig(:CompanyName).to_s,
            firstname:   args[:sendjim_contact].dig(:FirstName).to_s,
            lastname:    args[:sendjim_contact].dig(:LastName).to_s,
            address1:    args[:sendjim_contact].dig(:StreetAddress).to_s,
            city:        args[:sendjim_contact].dig(:City).to_s,
            state:       args[:sendjim_contact].dig(:State).to_s,
            zipcode:     args[:sendjim_contact].dig(:PostalCode).to_s
          )

          args[:sendjim_contact].dig(:Tags)&.each do |tag|
            Contacts::Tags::ApplyByNameJob.perform_later(
              contact_id: contact.id,
              user_id:    args.dig(:user_id) || contact.user_id,
              tag_name:   tag
            )
          end
        end

        # import SendJim contacts
        # Integration::Sendjim::V3::Sendjim.import_contacts()
        # (req) client_api_integration_id: (Integer)
        # (req) user_id:                   (Integer)
        # (opt) new_contacts_only:         (Boolean)
        def self.import_contacts(args = {})
          return unless args.dig(:client_api_integration_id).to_i.positive? && (client_api_integration = ClientApiIntegration.find_by(id: args[:client_api_integration_id].to_i, target: 'sendjim', name: '')) &&
                        self.valid_token?(client_api_integration)

          sj_client = Integrations::SendJim::V3::Sendjim.new(client_api_integration.token)
          page      = (args.dig(:page) || -1).to_i

          if page.negative?
            # break up SendJim Contacts into blocks
            page_count = sj_client.contacts_pages

            # generate DelayedJobs to import all SendJim contacts
            (1..page_count).each do |pp|
              data = args.merge({ page: pp })
              self.delay(
                run_at:              Time.current,
                priority:            DelayedJob.job_priority('sendjim_import_contacts_block'),
                queue:               DelayedJob.job_queue('sendjim_import_contacts_block'),
                user_id:             args.dig(:user_id),
                contact_id:          0,
                triggeraction_id:    0,
                contact_campaign_id: 0,
                group_process:       1,
                process:             'sendjim_import_contacts_block',
                data:
              ).import_contacts(data)
              # self.import_contacts(data)
            end
          else
            # get the ServiceMonster job data for a specific page
            sj_client.contacts(page)

            if sj_client.success?

              # import Contacts
              sj_client.result.each do |contact|
                data = args.merge({ client_id: client_api_integration.client_id, sendjim_contact: contact })
                self.delay(
                  run_at:              Time.current,
                  priority:            DelayedJob.job_priority('sendjim_import_contact'),
                  queue:               DelayedJob.job_queue('sendjim_import_contact'),
                  user_id:             args.dig(:user_id),
                  contact_id:          0,
                  triggeraction_id:    0,
                  contact_campaign_id: 0,
                  group_process:       0,
                  process:             'sendjim_import_contact',
                  data:
                ).import_contact(data)
                # self.import_contact(data)
              end
            end
          end

          self.update_contact_imports_remaining_count(client_api_integration.client, User.find_by(client_id: client_api_integration.client_id, id: args.dig(:user_id)))
        end

        # push Contact to SendJim
        # Integration::Sendjim::V3::Sendjim.push_contact_to_sendjim()
        # (req) contact:                (Contact)
        # (req) client_api_integration: (ClientApiIntegration)
        # (opt) push_tags:              (Boolean)
        def self.push_contact_to_sendjim(args = {})
          return unless args.dig(:contact).is_a?(Contact) && args.dig(:client_api_integration).is_a?(ClientApiIntegration)

          contact_ext_id = args[:contact].ext_references.find_by(target: 'sendjim')&.ext_id.to_i

          if contact_ext_id.zero? && self.valid_token?(args[:client_api_integration])
            sj_client = Integrations::SendJim::V3::Sendjim.new(args[:client_api_integration].token)

            contact_ext_id = sj_client.push_contact(
              firstname:    args[:contact].firstname,
              lastname:     args[:contact].lastname,
              address_01:   args[:contact].address1,
              address_02:   args[:contact].address2,
              city:         args[:contact].city,
              state:        args[:contact].state,
              postal_code:  args[:contact].zipcode,
              email:        args[:contact].email,
              phone_number: args[:contact].primary_phone&.phone.to_s,
              tag_names:    args[:push_tags].to_bool ? args[:contact].tags.map(&:name) : []
            )

            args[:contact].ext_references.create(target: 'sendjim', ext_id: contact_ext_id) if contact_ext_id.positive?
          end

          contact_ext_id
        end

        # send mailing to a Contact from SendJim
        # Integration::Sendjim::V3::Sendjim.send_card_from_sendjim()
        # (req) contact:                (Contact)
        # (req) client_api_integration: (ClientApiIntegration)
        # (req) push_contact:           (Hash)
        def self.send_card_from_sendjim(args = {})
          return unless args.dig(:contact).is_a?(Contact) && args.dig(:push_contact).present? && args.dig(:client_api_integration).is_a?(ClientApiIntegration)

          self.valid_token?(args[:client_api_integration])
          sj_client = Integrations::SendJim::V3::Sendjim.new(args[:client_api_integration].token)

          contact_ext_id = self.push_contact_to_sendjim(contact: args[:contact], client_api_integration: args[:client_api_integration], push_tags: args[:push_contact].dig(:send_tags))

          if contact_ext_id.positive?

            if args[:push_contact].dig(:quick_send_type).to_s.casecmp?('quick_send_mailing')
              sj_client.quick_send(
                ext_id:        contact_ext_id,
                quick_send_id: args[:push_contact].dig(:quick_send_id)
              )
            elsif args[:push_contact].dig(:quick_send_type).to_s.casecmp?('neighbor_mailing') && args[:push_contact].dig(:radius).positive?
              sj_client.neighbor_quick_send(
                address_01:       args[:contact].address1,
                address_02:       args[:contact].address2,
                city:             args[:contact].city,
                state:            args[:contact].state,
                postal_code:      args[:contact].zipcode,
                radius:           args[:push_contact].dig(:radius),
                same_street_only: args[:push_contact].dig(:same_street_only),
                quick_send_id:    args[:push_contact].dig(:quick_send_id)
              )
            elsif args[:push_contact].dig(:quick_send_type).to_s.casecmp?('neighbor_mailing') && args[:push_contact].dig(:neighbor_count).positive?
              sj_client.neighbor_quick_send(
                ext_id:           contact_ext_id,
                quick_send_id:    args[:push_contact].dig(:quick_send_id),
                neighbor_count:   args[:push_contact].dig(:neighbor_count),
                same_street_only: args[:push_contact].dig(:same_street_only)
              )
            end
          end

          args[:contact].postcards.create(
            client_id: args[:contact].client_id,
            tag_id:    args[:push_contact].dig(:tag_id),
            target:    'sendjim',
            card_id:   args[:push_contact].dig(:quick_send_id).to_s,
            result:    sj_client.success?.to_s,
            card_name: "SendJim Mailing (#{sj_client.quick_sends.find { |qs| qs[:QuickSendID] == args[:push_contact].dig(:quick_send_id) }&.dig(:Name).presence || 'Unknown'})"
          )

          return if sj_client.success?

          data = {
            contact_id: args[:contact].id,
            content:    "SendJim Mailing Failed! (#{sj_client.message.presence || 'Unknown Error'})"
          }
          args[:contact].user.delay(
            contact_campaign_id: 0,
            contact_id:          0,
            data:,
            priority:            DelayedJob.job_priority('send_text_to_user'),
            process:             'send_text_to_user',
            queue:               DelayedJob.job_queue('send_text_to_user'),
            run_at:              Time.current,
            triggeraction_id:    0,
            user_id:             args[:contact].user_id
          ).send_text(data)
        end

        # a Tag was applied to Contact / push to SendJim if Tag is selected
        # Integration::Sendjim::V3::Sendjim.push_tag_applied(contacttag: Contacttag)
        def self.push_tag_applied(args = {})
          contacttag = args.dig(:contacttag)

          return unless contacttag.is_a?(Contacttag) &&
                        (client_api_integration = ClientApiIntegration.find_by(client_id: contacttag.contact.client_id, target: 'sendjim', name: ''))

          client_api_integration.push_contacts&.map(&:symbolize_keys)&.each do |push_contact|
            self.send_card_from_sendjim(contact: contacttag.contact, client_api_integration:, push_contact:) if push_contact.dig(:tag_id) == contacttag.tag_id
          end
        end

        def self.update_contact_imports_remaining_count(client, user)
          html_string = self.contact_imports_remaining_string(user.id)

          UserCable.new.broadcast(client, user, { append: 'false', id: 'contact_imports_remaining', html: self.contact_imports_remaining_string(user.id) })

          UserCable.new.broadcast(client, user, { enable: 'true', id: 'import_contacts_button' }) if html_string.empty?
        end

        # validate the token
        # Integration::Sendjim::V3::Sendjim.valid_token?(ClientApiIntegration)
        # (req) client_api_integration: (ClientApiIntegration)
        def self.valid_token?(client_api_integration)
          if self.credentials_exist?(client_api_integration) && (sj_client = Integrations::SendJim::V3::Sendjim.new(client_api_integration&.token)) && sj_client.user.present?
            true
          elsif self.credentials_exist?(client_api_integration)
            client_api_integration&.update(token: '')
            false
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# app/models/integration/jobber/v20220915/import_contacts.rb
module Integration
  module Jobber
    module V20220915
      module ImportContacts
        IMPORT_BLOCK_COUNT = 50

        # import Contacts from Jobber clients
        # step 3 / import the Jobber client
        # jb_model.import_contact()
        #   (req) actions:          (Hash)
        #     see import_contact_actions
        #   (req) jobber_client_id: (String)
        #   (req) user_id:          (Integer)
        def import_contact(args = {})
          JsonLog.info 'Integration::Jobber::V20220915::ImportContacts.import_contact', { args: }
          return unless args.dig(:actions).is_a?(Hash) && args.dig(:jobber_client_id).to_s.present? && args.dig(:user_id).to_i.positive? && self.valid_credentials?

          jobber_client = @jb_client.client(args[:jobber_client_id])
          contact       = nil

          JsonLog.info 'Integration::Jobber::V20220915::ImportContacts.import_contact', { jobber_client: }

          if @jb_client.success? && ((!args[:actions][:eq_0][:import].to_bool && !args[:actions][:below_0][:import].to_bool && !args[:actions][:above_0][:import].to_bool) ||
             (args[:actions][:eq_0][:import].to_bool && jobber_client.dig(:balance).to_d.zero?) ||
             (args[:actions][:below_0][:import].to_bool && jobber_client.dig(:balance).to_d.negative?) ||
             (args[:actions][:above_0][:import].to_bool && jobber_client.dig(:balance).to_d.positive?))

            phones    = {}
            ok_2_text = 0
            @jb_client.result.dig(:phones).each do |p|
              phones[p.dig(:number).to_s.tr('^0-9', '')] = p.dig(:description).to_s
              ok_2_text = 1 if p.dig(:smsAllowed).to_bool
            end

            return false unless (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, phones:, emails: @jb_client.result.dig(:emails)&.first&.dig(:address).to_s, ext_refs: { 'jobber' => args[:jobber_client_id] }))

            contact.lastname       = (@jb_client.result.dig(:lastName) || contact.lastname).to_s
            contact.firstname      = (@jb_client.result.dig(:firstName) || contact.firstname).to_s
            contact.companyname    = (@jb_client.result.dig(:companyName) || contact.companyname).to_s
            contact.address1       = (@jb_client.result.dig(:billingAddress, :street1) || contact.address1).to_s
            contact.address2       = (@jb_client.result.dig(:billingAddress, :street2) || contact.address2).to_s
            contact.city           = (@jb_client.result.dig(:billingAddress, :city) || contact.city).to_s
            contact.state          = (@jb_client.result.dig(:billingAddress, :province) || contact.state).to_s
            contact.zipcode        = (@jb_client.result.dig(:billingAddress, :postalCode) || contact.zipcode).to_s
            contact.ok2text        = ok_2_text if contact.ok2text.to_i.positive?
            contact.ok2email       = 1
            contact.save

            @jb_client.result.dig(:tags, :nodes).each do |t|
              Contacts::Tags::ApplyByNameJob.perform_now(
                contact_id: contact.id,
                tag_name:   t[:label],
              ) if t.dig(:label).present?
            end

            self.import_contact_actions(contact, args[:actions], jobber_client.dig(:balance).to_d)
          end

          self.import_contacts_remaining_update(args[:user_id])
        end

        # st_model.import_contact_actions()
        #   (req) contact:         (Contact)
        #   (req) actions:         (Hash)
        #     (opt) above_0: (Hash)
        #       (opt) import: (Boolean)
        #       (opt) campaign_id:       (Integer)
        #       (opt) group_id:          (Integer)
        #       (opt) stage_id:          (Integer)
        #       (opt) tag_id:            (Integer)
        #       (opt) stop_campaign_ids: (Array)
        #     (opt) eq_0: (Hash)
        #       (opt) import: (Boolean)
        #       (opt) campaign_id:       (Integer)
        #       (opt) group_id:          (Integer)
        #       (opt) stage_id:          (Integer)
        #       (opt) tag_id:            (Integer)
        #       (opt) stop_campaign_ids: (Array)
        #     (opt) below_0: (Hash)
        #       (opt) import: (Boolean)
        #       (opt) campaign_id:       (Integer)
        #       (opt) group_id:          (Integer)
        #       (opt) stage_id:          (Integer)
        #       (opt) tag_id:            (Integer)
        #       (opt) stop_campaign_ids: (Array)
        #   (req) account_balance: (BigDecimal)
        def import_contact_actions(contact, actions, account_balance)
          JsonLog.info 'Integration::Jobber::V20220915::ImportContacts.import_contact_actions', { account_balance:, actions: }, contact_id: contact&.id
          return unless actions.is_a?(Hash) && contact.is_a?(Contact)

          # 0 balance actions
          if account_balance.to_d.zero?
            contact.process_actions(
              campaign_id:       actions.dig(:eq_0, :campaign_id).to_i,
              group_id:          actions.dig(:eq_0, :group_id).to_i,
              stage_id:          actions.dig(:eq_0, :stage_id).to_i,
              tag_id:            actions.dig(:eq_0, :tag_id).to_i,
              stop_campaign_ids: actions.dig(:eq_0, :stop_campaign_ids)
            )
          end

          # balance below 0 actions
          if account_balance.to_d.negative?
            contact.process_actions(
              campaign_id:       actions.dig(:below_0, :campaign_id).to_i,
              group_id:          actions.dig(:below_0, :group_id).to_i,
              stage_id:          actions.dig(:below_0, :stage_id).to_i,
              tag_id:            actions.dig(:below_0, :tag_id).to_i,
              stop_campaign_ids: actions.dig(:below_0, :stop_campaign_ids)
            )
          end

          # balance above 0 actions
          return unless account_balance.to_d.positive?

          contact.process_actions(
            campaign_id:       actions.dig(:above_0, :campaign_id).to_i,
            group_id:          actions.dig(:above_0, :group_id).to_i,
            stage_id:          actions.dig(:above_0, :stage_id).to_i,
            tag_id:            actions.dig(:above_0, :tag_id).to_i,
            stop_campaign_ids: actions.dig(:above_0, :stop_campaign_ids)
          )
        end

        # import Contacts from Jobber clients
        # step 2 / get the (IMPORT_BLOCK_COUNT) Jobber clients and split into 1 Delayed::Job/contact
        # st_model.import_contacts_blocks()
        #   (req) actions:        (Hash)
        #   (req) filter:         (Hash)
        #   (req) jobber_clients: (Array)
        #   (req) user_id:        (Integer)
        def import_contacts_blocks(args = {})
          JsonLog.info 'Integration::Jobber::V20220915::ImportContacts.import_contacts_blocks', { args: }
          return unless args.dig(:actions).is_a?(Hash) && args.dig(:filter).is_a?(Hash) && args.dig(:jobber_clients).is_a?(Array) && args.dig(:user_id).to_i.positive?

          run_at = Time.current

          args.dig(:jobber_clients).each do |jobber_client|
            data = {
              actions:          args[:actions],
              jobber_client_id: jobber_client.dig(:id),
              user_id:          args[:user_id]
            }
            self.delay(
              run_at:,
              priority:            DelayedJob.job_priority('jobber_import_contact'),
              queue:               DelayedJob.job_queue('jobber_import_contact'),
              user_id:             args[:user_id],
              contact_id:          0,
              triggeraction_id:    0,
              contact_campaign_id: 0,
              group_process:       0,
              process:             'jobber_import_contact',
              data:
            ).import_contact(data)

            run_at += 1.second
          end

          self.import_contacts_remaining_update(args[:user_id])
        end

        # import Contacts from Jobber clients
        # step 1 / get the Jobber clients & create 1 Delayed::Job/(IMPORT_BLOCK_COUNT)
        # jb_model.import_contacts)
        #   (req) user_id: (Integer)
        #   (opt) filter:  (Hash)
        #     (opt) is_company:    (Boolean)
        #     (opt) is_lead:       (Boolean)
        #     (opt) is_archived:   (Boolean)
        #     (opt) updated_at  (Hash)
        #       (opt) after:  (DateTime)
        #       (opt) before: (DateTime)
        #     (opt) created_at:  (Hash)
        #       (opt) after:  (DateTime)
        #       (opt) before: (DateTime)
        #     (opt) tags:          (Array)
        #   (opt) actions: (Hash)
        #     see import_contact_actions
        def import_contacts(args = {})
          JsonLog.info 'Integration::Jobber::V20220915::ImportContacts.import_contacts', { args: }
          return unless args.dig(:user_id).to_i.positive? && self.valid_credentials?

          run_at                      = Time.current
          end_cursor                  = ''
          filter                      = {}
          filter[:isArchived]         = args[:filter][:is_archived].to_bool unless args.dig(:filter, :is_archived).nil?
          filter[:isCompany]          = args[:filter][:is_company].to_bool unless args.dig(:filter, :is_company).nil?
          filter[:isLead]             = args[:filter][:is_lead].to_bool unless args.dig(:filter, :is_lead).nil?

          if args.dig(:filter, :created_at, :before).respond_to?(:iso8601) || args.dig(:filter, :created_at, :after).respond_to?(:iso8601)
            filter[:createdAt]          = {}
            filter[:createdAt][:after]  = args[:filter][:created_at][:after].iso8601 if args.dig(:filter, :created_at, :after).respond_to?(:iso8601)
            filter[:createdAt][:before] = args[:filter][:created_at][:before].iso8601 if args.dig(:filter, :created_at, :before).respond_to?(:iso8601)
          end

          if args.dig(:filter, :updated_at, :before).respond_to?(:iso8601) || args.dig(:filter, :updated_at, :after).respond_to?(:iso8601)
            filter[:updatedAt]          = {}
            filter[:updatedAt][:after]  = args[:filter][:updated_at][:after].iso8601 if args.dig(:filter, :updated_at, :after).respond_to?(:iso8601)
            filter[:updatedAt][:before] = args[:filter][:updated_at][:before].iso8601 if args.dig(:filter, :updated_at, :before).respond_to?(:iso8601)
          end

          filter[:tags] = args[:filter][:tags] if args.dig(:filter, :tags).present?

          loop do
            @jb_client.clients(
              page_size:  IMPORT_BLOCK_COUNT,
              end_cursor:,
              filter:
            )

            if @jb_client.result.present?
              data = {
                actions:        args.dig(:actions),
                filter:,
                jobber_clients: @jb_client.result,
                user_id:        args[:user_id]
              }
              self.delay(
                run_at:,
                priority:            DelayedJob.job_priority('jobber_import_contacts_blocks'),
                queue:               DelayedJob.job_queue('jobber_import_contacts_blocks'),
                user_id:             args[:user_id],
                contact_id:          0,
                triggeraction_id:    0,
                contact_campaign_id: 0,
                group_process:       0,
                process:             'jobber_import_contacts_blocks',
                data:
              ).import_contacts_blocks(data)
            end

            break unless @jb_client.more_results

            end_cursor = @jb_client.end_cursor
            run_at    += IMPORT_BLOCK_COUNT.seconds
          end

          self.import_contacts_remaining_update(args[:user_id], false)
        end

        # count the number of Contacts remaining to be imported in Delayed::Job
        # jb_model.import_contacts_remaining_count()
        #   (req) user_id: (Integer)
        def import_contacts_remaining_count(user_id)
          contact_count = 0

          if user_id.to_i.positive?
            contact_count += [0, ((Delayed::Job.where(process: 'jobber_import_contacts_blocks', user_id:).count - 1) * IMPORT_BLOCK_COUNT)].max
            contact_count += [0, Delayed::Job.where(process: 'jobber_import_contact', user_id:).count - 1].max
          end

          contact_count
        end

        # return a string that may be used to inform the User how many more Jobber clients are remaining in the queue to be imported
        # jb_model.import_contacts_remaining_string()
        #   (req) user_id: (Integer)
        # rubocop:disable Style/OptionalBooleanParameter
        def import_contacts_remaining_string(user_id, count_jobber_import_contacts = true)
          if count_jobber_import_contacts && Delayed::Job.where(process: 'jobber_import_contacts', user_id:).any?
            'Contact imports queued.'
          else
            remaining_count = self.import_contacts_remaining_count(user_id)

            if remaining_count.positive?
              "Contacts awaiting import: ~ #{remaining_count}"
            else
              ''
            end
          end
        end
        # rubocop:enable Style/OptionalBooleanParameter

        # update contact_imports_remaining_count element showing remaining Jobber clients to import
        # jb_model.import_contacts_remaining_update()
        #   (req) user_id: (Integer)
        # rubocop:disable Style/OptionalBooleanParameter
        def import_contacts_remaining_update(user_id, count_jobber_import_contacts = true)
          current_logger_level = Rails.logger.level
          Rails.logger.level = :error

          if user_id.to_i.positive? && (user = User.find_by(id: user_id))
            UserCable.new.broadcast(user.client, user, { append: 'false', id: 'contact_imports_remaining_count', html: self.import_contacts_remaining_string(user_id, count_jobber_import_contacts) })
          end

          Rails.logger.level = current_logger_level
        end
        # rubocop:enable Style/OptionalBooleanParameter
      end
    end
  end
end

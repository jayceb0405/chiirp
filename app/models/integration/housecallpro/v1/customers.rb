# frozen_string_literal: true

# app/models/Integration/housecallpro/v1/customers.rb
module Integration
  module Housecallpro
    module V1
      module Customers
        # return a string that may be used to inform the User how many more Housecall Pro customers are remaining in the queue to be imported
        # hcp_model.contact_imports_remaining_string
        def contact_imports_remaining_string
          delayed_jobs            = DelayedJob.where(user_id: @client.users, process: %w[housecallpro_update_contact_from_customer housecallpro_import_customers housecallpro_import_customer_group]).group(:process).count
          imports                 = delayed_jobs.dig('housecallpro_import_customers').to_i
          grouped_contact_imports = delayed_jobs.dig('housecallpro_import_customer_group').to_i * self.import_block_size
          contact_imports         = delayed_jobs.dig('housecallpro_update_contact_from_customer').to_i

          if imports.positive? && (grouped_contact_imports + contact_imports).zero?
            'Queued'
          elsif (imports + grouped_contact_imports + contact_imports).to_i > 1
            "#{grouped_contact_imports.positive? ? '< ' : ''}#{grouped_contact_imports + contact_imports}"
          else
            '0'
          end
        end

        # import a page of Housecall Pro customers
        # hcp_model.import_customer_group()
        #   (req) page:              (Integer)
        #   (req) page_size:         (Integer)
        #   (opt) new_contacts_only: (Boolean)
        #   (opt) user_id:           (Integer)
        def import_customer_group(args = {})
          JsonLog.info 'Integration::Housecallpro::V1::Base.import_customer_group', { args: }
          user_id                = args.dig(:user_id).to_i
          new_contacts_only      = args.dig(:new_contacts_only).nil? ? true : args.dig(:new_contacts_only).to_bool
          page                   = args.dig(:page).to_i
          page_size              = args.dig(:page_size).to_i

          return false unless self.valid_credentials? && page.positive? && page_size.positive?

          @hcp_client.customers(page:, page_size:).each do |customer|
            self.delay(
              run_at:              Time.current,
              priority:            DelayedJob.job_priority('housecallpro_update_contact_from_customer'),
              queue:               DelayedJob.job_queue('housecallpro_update_contact_from_customer'),
              contact_id:          0,
              contact_campaign_id: 0,
              user_id:,
              triggeraction_id:    0,
              process:             'housecallpro_update_contact_from_customer',
              group_process:       0,
              data:                { customer:, new_contacts_only: }
            ).update_contact_from_customer(customer:, new_contacts_only:)
          end

          CableBroadcaster.new.contacts_import_remaining(client: @client.id, count: self.contact_imports_remaining_string)

          true
        end

        # import Housecall Pro customers
        # hcp_model.import_customers()
        #   (opt) user_id:           (Integer)
        #   (opt) new_contacts_only: (Boolean)
        def import_customers(args)
          JsonLog.info 'Integration::Housecallpro::V1::Base.import_customers', { args: }
          user_id                = args.dig(:user_id).to_i
          new_contacts_only      = args.dig(:new_contacts_only).nil? ? true : args.dig(:new_contacts_only).to_bool

          return false unless self.valid_credentials?

          page   = 1
          run_at = Time.current

          while page <= (@hcp_client.customers_count.to_f / self.import_block_size).ceil
            self.delay(
              run_at:,
              priority:            DelayedJob.job_priority('housecallpro_import_customer_group'),
              queue:               DelayedJob.job_queue('housecallpro_import_customer_group'),
              contact_id:          0,
              contact_campaign_id: 0,
              user_id:,
              triggeraction_id:    0,
              process:             'housecallpro_import_customer_group',
              group_process:       0,
              data:                { user_id:, new_contacts_only:, page:, page_size: self.import_block_size }
            ).import_customer_group(user_id:, new_contacts_only:, page:, page_size: self.import_block_size)

            page   += 1
            run_at += 1.minute
          end

          CableBroadcaster.new.contacts_import_remaining(client: @client.id, count: self.contact_imports_remaining_string)

          true
        end

        # add/update a Contact from a Housecall Pro customer
        # hcp_model.update_contact_from_customer(customer: Hash, new_contacts_only: Boolean)
        #   (req) customer:          (Hash)
        #   (opt) new_contacts_only: (Boolean)
        def update_contact_from_customer(args = {})
          JsonLog.info 'Integration::Housecallpro::V1::Base.update_contact_from_customer', { args: }
          customer                = args.dig(:customer)
          new_contacts_only       = args.dig(:new_contacts_only).nil? ? true : args.dig(:new_contacts_only).to_bool

          return false unless customer.is_a?(Hash)

          phones = {}
          phones[customer[:mobile_number].to_s] = 'mobile' if customer.dig(:mobile_number).present?
          phones[customer[:work_number].to_s]   = 'work' if customer.dig(:work_number).present?
          phones[customer[:home_number].to_s]   = 'home' if customer.dig(:home_number).present?

          if (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client.id, phones:, emails: [customer.dig(:email).to_s], ext_refs: { 'housecallpro' => customer.dig(:id).to_s })) && (contact.new_record? || !new_contacts_only)
            contact.update(
              firstname:      customer.dig(:first_name).to_s,
              lastname:       customer.dig(:last_name).to_s,
              address1:       customer.dig(:addresses)&.first&.dig(:street).to_s,
              address2:       customer.dig(:addresses)&.first&.dig(:street_line_2).to_s,
              city:           customer.dig(:addresses)&.first&.dig(:city).to_s,
              state:          customer.dig(:addresses)&.first&.dig(:state).to_s,
              zipcode:        customer.dig(:addresses)&.first&.dig(:zip).to_s,
              lead_source_id: self.convert_hcp_lead_source_id(customer.dig(:lead_source))&.id
            )

            apply_tags_from_webhook(contact, customer.dig(:tags))
          end

          CableBroadcaster.new.contacts_import_remaining(client: @client.id, count: self.contact_imports_remaining_string)

          true
        end

        # update or create ClientCustomFields required for Housecall Pro (Chiirp) integration
        # hcp_model.update_required_custom_fields
        def update_required_custom_fields
          # first we scan through existing ClientCustomFields and match any existing data
          @client.client_custom_fields.each do |client_custom_field|
            if (custom_field = custom_fields.find { |cf| cf[:var_var] == client_custom_field.var_var })

              unless client_custom_field.var_name == custom_field[:var_name] && client_custom_field.var_type == custom_field[:var_type] &&
                     client_custom_field.var_options == custom_field[:var_options] && client_custom_field.var_placeholder == custom_field[:var_placeholder] &&
                     client_custom_field.image_is_valid == custom_field[:image_is_valid]

                client_custom_field.update(
                  var_name:        custom_field[:var_name],
                  var_type:        custom_field[:var_type],
                  var_options:     custom_field[:var_options],
                  var_placeholder: custom_field[:var_placeholder],
                  image_is_valid:  custom_field[:image_is_valid]
                )
              end

              custom_field[:client_custom_field_id] = client_custom_field.id
            end
          end

          # then we scan through custom_fields array and create any ClientCustomFields that were not found
          REQUIRED_CLIENT_CUSTOM_FIELDS.each do |custom_field|
            if custom_field[:client_custom_field_id].zero?
              client_custom_field = @client.client_custom_fields.create(
                var_name:        custom_field[:var_name],
                var_var:         custom_field[:var_var],
                var_type:        custom_field[:var_type],
                var_options:     custom_field[:var_options],
                var_placeholder: custom_field[:var_placeholder],
                var_important:   custom_field[:var_important],
                image_is_valid:  custom_field[:image_is_valid]
              )
              custom_field[:client_custom_field_id] = client_custom_field.id
            end

            @client_api_integration.custom_fields[custom_field[:var_var]] = custom_field[:client_custom_field_id].to_i
          end

          @client_api_integration.save
        end
      end
    end
  end
end

# frozen_string_literal: true

# app/models/integration/fieldpulse/v1/contacts.rb
module Integration
  module Fieldpulse
    module V1
      module Contacts
        # find or create a Contact based on incoming webhook data
        # Integration::Fieldpulse::V1::Contacts.find_or_create_contact()
        #   (opt) fp_customer: (Hash)
        #   (opt) raw_params:  (Hash)
        def find_or_create_contact(**args)
          return nil if (fp_customer = args.dig(:fp_customer) || customer(fp_customer_id: args.dig(:raw_params, :data, :object, :customer_id).to_i)).blank? ||
                        (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client.id, phones: collect_phones(fp_customer), emails: collect_emails(fp_customer), ext_refs: { 'fieldpulse' => fp_customer.dig(:id).presence })).blank?

          contact.update(
            firstname:   (fp_customer.dig(:first_name).presence || contact.firstname).to_s,
            lastname:    (fp_customer.dig(:last_name).presence || contact.lastname).to_s,
            companyname: (fp_customer.dig(:company_name).presence || contact.companyname).to_s,
            address1:    (fp_customer.dig(:address_1).presence || contact.address1).to_s,
            address2:    (fp_customer.dig(:address_2).presence || contact.address2).to_s,
            city:        (fp_customer.dig(:city).presence || contact.city).to_s,
            state:       (fp_customer.dig(:state).presence || contact.state).to_s,
            zipcode:     (fp_customer.dig(:zip_code).presence || contact.zipcode).to_s
          )

          contact
        end
        ############################################################################################################
        # example of a webhook endpoint
        ############################################################################################################
        # {
        #   trigger: 'Job Workflow Custom Status Update',
        #   message: 'UPDATE ON JOBS FOR status_id',
        #   data:    {
        #     old_value: 920838,
        #     new_value: 920839,
        #     object:    {
        #       id:                     8345173,
        #       job_type:               'Job for JimBob Martin',
        #       customer_id:            7796731,
        #       status:                 6,
        #       status_id:              920839,
        #       status_workflow_id:     173020,
        #       in_progress_status_log: 808,
        #       updated_at:             '2024-11-19 22:32:55'
        #     }
        #   },
        #   company: 'FieldPulse_Chiirp_114785'
        # }
        ############################################################################################################
        # example of a customer response
        ############################################################################################################
        # {
        #   id:                                    7796731,
        #   company_id:                            114785,
        #   mongo_id:                              nil,
        #   email:                                 'jimbob@asdf.org',
        #   phone:                                 '8021234567',
        #   city:                                  nil,
        #   state:                                 nil,
        #   notes:                                 '',
        #   address_1:                             nil,
        #   address_2:                             nil,
        #   cuid:                                  1003,
        #   first_name:                            'JimBob',
        #   middle_name:                           nil,
        #   last_name:                             'Martin',
        #   company_name:                          '',
        #   zip_code:                              nil,
        #   searchable:                            'JimBob Martin',
        #   sort_key:                              'jimbob martin',
        #   status:                                'current customer',
        #   has_different_billing_address:         false,
        #   alt_email:                             '',
        #   phone_e164:                            nil,
        #   qbo_id:                                nil,
        #   title:                                 nil,
        #   suffix:                                nil,
        #   alt_phone:                             '9125554568',
        #   billing_address_1:                     '',
        #   billing_address_2:                     '',
        #   billing_city:                          '',
        #   billing_state:                         '',
        #   fax:                                   '',
        #   skype:                                 '',
        #   assigned_to:                           190917,
        #   billing_zip_code:                      '',
        #   secondary_first_name:                  '',
        #   secondary_last_name:                   '',
        #   secondary_email:                       '',
        #   secondary_phone:                       '',
        #   use_company_name:                      nil,
        #   dial_phone:                            '',
        #   mobile_phone:                          '',
        #   website:                               '',
        #   qbo_sync_token:                        nil,
        #   last_qbo_sync:                         nil,
        #   created_at:                            '2024-10-02 15:14:12',
        #   updated_at:                            '2024-10-02 16:23:39',
        #   deleted_at:                            nil,
        #   parent_id:                             nil,
        #   postal_code:                           nil,
        #   alt_first_name:                        nil,
        #   alt_last_name:                         nil,
        #   lead_source:                           nil,
        #   service_address_1:                     nil,
        #   service_address_2:                     nil,
        #   service_address_city:                  nil,
        #   service_address_state:                 nil,
        #   service_address_zip_code:              nil,
        #   job_notes:                             '',
        #   account_type:                          'individual',
        #   parent_id_previous:                    nil,
        #   address1:                              nil,
        #   xero_id:                               nil,
        #   is_sync:                               nil,
        #   notes_old:                             nil,
        #   different_billing_address:             nil,
        #   xero_group_id:                         nil,
        #   dev_qbo:                               nil,
        #   source:                                nil,
        #   secondar_last_name:                    nil,
        #   sync_status:                           nil,
        #   xero_guid:                             nil,
        #   display_name:                          'JimBob Martin',
        #   uuid:                                  '5e6440f6-b527-4fd5-8dab-9b9661d60d94',
        #   xero_updated_date_utc:                 nil,
        #   country_code:                          'US',
        #   country_phone_code:                    'US',
        #   has_valid_phone:                       false,
        #   alt_phone_e164:                        '+19125554568',
        #   secondary_phone_e164:                  nil,
        #   searchable_number:                     '+19125554568',
        #   phone_validation_message:              'Number does not match the provided country.',
        #   lead_source_id:                        843250,
        #   servicerocketpro_id:                   nil,
        #   service_titan_id:                      nil,
        #   pipeline_status_id:                    nil,
        #   next_steps:                            '',
        #   qbd_id:                                nil,
        #   qbd_edit_sequence:                     nil,
        #   merged_customer_id:                    nil,
        #   pipeline_status_updated_at:            '2024-10-02 15:14:12',
        #   mailchimp_contact_id:                  nil,
        #   is_tax_exempt:                         false,
        #   qbo_tax_exempt_reason:                 nil,
        #   search_text:                           "'jimbob':2,4,6,8 'jimbob@asdf.org':1 'martin':3,5,7,9",
        #   import_id:                             nil,
        #   qbd_fullname:                          nil,
        #   qbd_addr_company_name:                 false,
        #   qbd_addr_first_last_name:              false,
        #   nicejob_id:                            nil,
        #   marketing360_id:                       nil,
        #   qbo_is_project:                        false,
        #   asset_display_settings:                {
        #     is_asset_company_header_visible:       true,
        #     is_asset_customer_header_visible:      true,
        #     is_asset_summary_visible:              true,
        #     is_asset_notes_visible:                true,
        #     is_asset_details_visible:              true,
        #     is_asset_warranty_information_visible: true,
        #     is_asset_conditional_visible:          true,
        #     asset_file_size:                       'large',
        #     asset_update_entity_mode:              'all',
        #     is_asset_updates_files_visible:        true,
        #     asset_update_file_size:                'large',
        #     is_asset_files_visible:                true,
        #     email_body_message:                    '',
        #     is_asset_custom_fields_visible:        true
        #   },
        #   next_sync_allowed_at:                  nil,
        #   sync_version:                          nil,
        #   job_display_settings:                  {
        #     is_job_company_header_visible:  true,
        #     is_job_customer_header_visible: true,
        #     is_job_summary_visible:         true,
        #     is_job_notes_visible:           true,
        #     is_job_custom_fields_visible:   true,
        #     is_job_field_notes_visible:     true,
        #     is_job_details_visible:         true,
        #     is_job_subtasks_visible:        true,
        #     is_job_visits_visible:          true,
        #     job_file_size:                  'large',
        #     is_job_files_visible:           true,
        #     is_folder_section_visible:      true,
        #     is_job_date_visible:            true,
        #     is_job_time_visible:            true,
        #     is_job_location_title_visible:  false
        #   },
        #   default_invoice_due_date:              nil,
        #   default_estimate_expiration_date:      nil,
        #   is_phone_notification_subscribed:      true,
        #   is_email_notification_subscribed:      true,
        #   billing_address_3:                     '',
        #   billing_address_4:                     '',
        #   billing_address_5:                     '',
        #   is_created_outside_franchise_category: false,
        #   price_tier_id:                         nil,
        #   has_available_forms:                   false,
        #   tags:                                  [],
        #   customfields:                          []
        # }

        private

        def collect_emails(fp_customer)
          [fp_customer.dig(:email).to_s.downcase, fp_customer.dig(:alt_email).to_s.downcase].compact_blank.uniq
        end

        def collect_phones(fp_customer)
          phones = {}
          phones[fp_customer.dig(:phone).to_s.clean_phone] = 'mobile' if fp_customer.dig(:phone).to_s.tr('^0-9', '').length == 10
          phones[fp_customer.dig(:alt_phone).to_s.clean_phone] = 'mobile' if fp_customer.dig(:alt_phone).to_s.tr('^0-9', '').length == 10
          phones[fp_customer.dig(:dial_phone).to_s.clean_phone] = 'voice' if fp_customer.dig(:dial_phone).to_s.tr('^0-9', '').length == 10
          phones[fp_customer.dig(:mobile_phone).to_s.clean_phone] = 'mobile' if fp_customer.dig(:mobile_phone).to_s.tr('^0-9', '').length == 10

          phones
        end
      end
    end
  end
end

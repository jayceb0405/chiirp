# frozen_string_literal: true

# app/models/integration/fieldpulse/v1/jobs.rb
module Integration
  module Fieldpulse
    module V1
      module Jobs
        # find or create a Contacts::Job based on FieldPulse job data
        # Integration::Fieldpulse::V1::Contacts.find_or_create_contact_job()
        #   (req) contact: (Contact)
        #   (req) fp_job:  (Integer)
        def find_or_create_contact_job(**args)
          Rails.logger.info "args: #{args.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          return nil unless args.dig(:contact).is_a?(Contact) && args.dig(:fp_job).is_a?(Hash) &&
                            (contact_job = args[:contact].jobs.find_or_initialize_by(ext_source: 'fieldpulse', ext_id: args.dig(:fp_job, :id))).present?

          # start_date_updated = Chronic.parse(args.dig(:startAt)) != contact_job.scheduled_start_at
          # tech_updated       = args.dig(:visitSchedule, :assignedTo, :nodes)&.first&.dig(:id) != contact_job.ext_tech_id

          contact_job.update(
            status:                            (args.dig(:fp_job, :status).presence || contact_job.status).to_s,
            # description:        (args.dig(:job_type).presence || contact_job.description).to_s,
            job_type:                          (args.dig(:fp_job, :job_type).presence || contact_job.job_type).to_s,
            address_01:                        (args.dig(:fp_job, :entity_location, :address_1).presence || contact_job.address_01).to_s,
            address_02:                        (args.dig(:fp_job, :entity_location, :address_2).presence || contact_job.address_02).to_s,
            city:                              (args.dig(:fp_job, :entity_location, :city).presence || contact_job.city).to_s,
            state:                             (args.dig(:fp_job, :entity_location, :state).presence || contact_job.state).to_s,
            postal_code:                       (args.dig(:fp_job, :entity_location, :zip_code).presence || contact_job.postal_code).to_s,
            scheduled_start_at:                datetime_from_webhook(args[:contact], args.dig(:fp_job, :start_time)) || contact_job.scheduled_start_at,
            scheduled_end_at:                  datetime_from_webhook(args[:contact], args.dig(:fp_job, :end_time)) || contact_job.scheduled_end_at,
            scheduled_arrival_window_start_at: datetime_from_webhook(args[:contact], args.dig(:fp_job, :customer_arrival_window_start_time)) || contact_job.scheduled_arrival_window_start_at,
            scheduled_arrival_window_end_at:   datetime_from_webhook(args[:contact], args.dig(:fp_job, :customer_arrival_window_end_time)) || contact_job.scheduled_arrival_window_end_at,
            total_amount:                      (args.dig(:fp_job, :total_price).presence || contact_job.total_amount).to_d,
            ext_tech_id:                       (args.dig(:fp_job, :assignments)&.first&.dig(:user_id).presence || contact_job.ext_tech_id).to_s,
            notes:                             (args.dig(:fp_job, :notes).presence || contact_job.notes).to_s
          )

          contact_job
        end
        # example of FieldPulse job data:
        # {
        #   id:                                 8345173,
        #   company_id:                         114785,
        #   mongo_id:                           nil,
        #   cuid:                               1003,
        #   author_id:                          190917,
        #   customer_id:                        7796731,
        #   job_type:                           'Job for JimBob Martin',
        #   status:                             1,
        #   start_time:                         '2024-10-12 12:00:00',
        #   end_time:                           '2024-10-12 14:00:00',
        #   due_date:                           nil,
        #   billing:                            1,
        #   assignment_count:                   1,
        #   in_progress_status_log:             808,
        #   invoice_status:                     nil,
        #   notes:                              '',
        #   location_old:                       nil,
        #   location_coords:                    nil,
        #   tags_string:                        nil,
        #   created_at:                         '2024-10-09 19:06:23',
        #   updated_at:                         '2024-10-09 19:56:43',
        #   deleted_at:                         nil,
        #   project_id:                         nil,
        #   recurring_parent_id:                nil,
        #   upcoming_job_notified:              nil,
        #   detached_from_recurring_parent:     nil,
        #   maintenance_agreement_id:           nil,
        #   maintenance_occurrence_id:          nil,
        #   uuid:                               nil,
        #   field_notes:                        '',
        #   hazardco_swms_id:                   nil,
        #   service_titan_id:                   nil,
        #   service_titan_location_id:          nil,
        #   type:                               'job',
        #   task_category_id:                   nil,
        #   on_the_way_status_log:              165,
        #   is_template:                        false,
        #   template_id:                        nil,
        #   location_id:                        8399883,
        #   customer_contact_id:                nil,
        #   subtitle:                           '',
        #   import_id:                          nil,
        #   status_id:                          920838,
        #   status_workflow_id:                 173020,
        #   is_visible:                         true,
        #   nicejob_id:                         nil,
        #   completed_at:                       nil,
        #   customer_arrival_window_start_time: '2024-10-09 12:00:00',
        #   customer_arrival_window_end_time:   '2024-10-09 14:00:00',
        #   source:                             nil,
        #   status_log:                         { in_progress: 808, on_the_way: 165, pending: 0, completed: 0 },
        #   customfields:                       [],
        #   total_price:                        '0.00',
        #   has_available_forms:                false,
        #   tags:                               [],
        #   map:                                nil,
        #   customer_contact:                   nil,
        #   assignments:                        [{
        #     company_id:      114785,
        #     user_id:         190919,
        #     assignable_id:   8345173,
        #     assignable_type: 'App\\Http\\Api\\Core\\Models\\BaseJob',
        #     created_at:      '2024-10-09T19:51:48.000000Z',
        #     updated_at:      '2024-10-09T19:51:48.000000Z',
        #     team_id:         130453,
        #     mongo_id:        nil,
        #     id:              38770286
        #   }],
        #   customer:                           {
        #     id:                                    7796731,
        #     company_id:                            114785,
        #     mongo_id:                              nil,
        #     email:                                 'jimbob@asdf.org',
        #     phone:                                 '8021234567',
        #     city:                                  nil,
        #     state:                                 nil,
        #     notes:                                 '',
        #     address_1:                             nil,
        #     address_2:                             nil,
        #     cuid:                                  1003,
        #     first_name:                            'JimBob',
        #     middle_name:                           nil,
        #     last_name:                             'Martin',
        #     company_name:                          '',
        #     zip_code:                              nil,
        #     searchable:                            'JimBob Martin',
        #     sort_key:                              'jimbob martin',
        #     status:                                'current customer',
        #     has_different_billing_address:         false,
        #     alt_email:                             '',
        #     phone_e164:                            nil,
        #     qbo_id:                                nil,
        #     title:                                 nil,
        #     suffix:                                nil,
        #     alt_phone:                             '9125554568',
        #     billing_address_1:                     '',
        #     billing_address_2:                     '',
        #     billing_city:                          '',
        #     billing_state:                         '',
        #     fax:                                   '',
        #     skype:                                 '',
        #     assigned_to:                           190917,
        #     billing_zip_code:                      '',
        #     secondary_first_name:                  '',
        #     secondary_last_name:                   '',
        #     secondary_email:                       '',
        #     secondary_phone:                       '',
        #     use_company_name:                      nil,
        #     dial_phone:                            '',
        #     mobile_phone:                          '',
        #     website:                               '',
        #     qbo_sync_token:                        nil,
        #     last_qbo_sync:                         nil,
        #     created_at:                            '2024-10-02 15:14:12',
        #     updated_at:                            '2024-10-02 16:23:39',
        #     deleted_at:                            nil,
        #     parent_id:                             nil,
        #     postal_code:                           nil,
        #     alt_first_name:                        nil,
        #     alt_last_name:                         nil,
        #     lead_source:                           nil,
        #     service_address_1:                     nil,
        #     service_address_2:                     nil,
        #     service_address_city:                  nil,
        #     service_address_state:                 nil,
        #     service_address_zip_code:              nil,
        #     job_notes:                             '',
        #     account_type:                          'individual',
        #     parent_id_previous:                    nil,
        #     address1:                              nil,
        #     xero_id:                               nil,
        #     is_sync:                               nil,
        #     notes_old:                             nil,
        #     different_billing_address:             nil,
        #     xero_group_id:                         nil,
        #     dev_qbo:                               nil,
        #     source:                                nil,
        #     secondar_last_name:                    nil,
        #     sync_status:                           nil,
        #     xero_guid:                             nil,
        #     display_name:                          'JimBob Martin',
        #     uuid:                                  '5e6440f6-b527-4fd5-8dab-9b9661d60d94',
        #     xero_updated_date_utc:                 nil,
        #     country_code:                          'US',
        #     country_phone_code:                    'US',
        #     has_valid_phone:                       false,
        #     alt_phone_e164:                        '+19125554568',
        #     secondary_phone_e164:                  nil,
        #     searchable_number:                     '+19125554568',
        #     phone_validation_message:              'Number does not match the provided country.',
        #     lead_source_id:                        843250,
        #     servicerocketpro_id:                   nil,
        #     service_titan_id:                      nil,
        #     pipeline_status_id:                    nil,
        #     next_steps:                            '',
        #     qbd_id:                                nil,
        #     qbd_edit_sequence:                     nil,
        #     merged_customer_id:                    nil,
        #     pipeline_status_updated_at:            '2024-10-02 15:14:12',
        #     mailchimp_contact_id:                  nil,
        #     is_tax_exempt:                         false,
        #     qbo_tax_exempt_reason:                 nil,
        #     search_text:                           "'jimbob':2,4,6,8 'jimbob@asdf.org':1 'martin':3,5,7,9",
        #     import_id:                             nil,
        #     qbd_fullname:                          nil,
        #     qbd_addr_company_name:                 false,
        #     qbd_addr_first_last_name:              false,
        #     nicejob_id:                            nil,
        #     marketing360_id:                       nil,
        #     qbo_is_project:                        false,
        #     asset_display_settings:                {
        #       is_asset_company_header_visible:       true,
        #       is_asset_customer_header_visible:      true,
        #       is_asset_summary_visible:              true,
        #       is_asset_notes_visible:                true,
        #       is_asset_details_visible:              true,
        #       is_asset_warranty_information_visible: true,
        #       is_asset_conditional_visible:          true,
        #       asset_file_size:                       'large',
        #       asset_update_entity_mode:              'all',
        #       is_asset_updates_files_visible:        true,
        #       asset_update_file_size:                'large',
        #       is_asset_files_visible:                true,
        #       email_body_message:                    '',
        #       is_asset_custom_fields_visible:        true
        #     },
        #     next_sync_allowed_at:                  nil,
        #     sync_version:                          nil,
        #     job_display_settings:                  {
        #       is_job_company_header_visible:  true,
        #       is_job_customer_header_visible: true,
        #       is_job_summary_visible:         true,
        #       is_job_notes_visible:           true,
        #       is_job_custom_fields_visible:   true,
        #       is_job_field_notes_visible:     true,
        #       is_job_details_visible:         true,
        #       is_job_subtasks_visible:        true,
        #       is_job_visits_visible:          true,
        #       job_file_size:                  'large',
        #       is_job_files_visible:           true,
        #       is_folder_section_visible:      true,
        #       is_job_date_visible:            true,
        #       is_job_time_visible:            true,
        #       is_job_location_title_visible:  false
        #     },
        #     default_invoice_due_date:              nil,
        #     default_estimate_expiration_date:      nil,
        #     is_phone_notification_subscribed:      true,
        #     is_email_notification_subscribed:      true,
        #     billing_address_3:                     '',
        #     billing_address_4:                     '',
        #     billing_address_5:                     '',
        #     is_created_outside_franchise_category: false,
        #     tags:                                  [],
        #     customfields:                          []
        #   },
        #   entity_location:                    {
        #     id:                          8399883,
        #     company_id:                  114785,
        #     author_id:                   190917,
        #     object_id:                   7796731,
        #     object_type:                 'App\\Http\\Api\\Core\\Models\\BaseCustomer',
        #     title:                       'Main Location',
        #     address_1:                   '',
        #     address_2:                   '',
        #     city:                        '',
        #     state:                       '',
        #     zip_code:                    '',
        #     notes:                       '',
        #     is_main_location:            true,
        #     created_at:                  '2024-10-02 15:14:12',
        #     updated_at:                  '2024-10-02 15:14:12',
        #     deleted_at:                  nil,
        #     location_coords:             nil,
        #     order_index:                 1,
        #     is_primary_location:         true,
        #     primary_customer_contact_id: nil,
        #     search_text:                 '',
        #     import_id:                   nil,
        #     address_3:                   '',
        #     address_4:                   '',
        #     address_5:                   '',
        #     tax_rate:                    nil
        #   }
        # }

        # retrieve a specific FieldPulse job
        # fp_model.job()
        #   (req) fp_job_id: (Integer)
        def job(**args)
          reset_attributes

          @fp_client.job(args.dig(:fp_job_id).to_i)
          update_attributes_from_client

          if @fp_client.success? && @fp_client.result.dig(:response).is_a?(Hash)
            @result = @fp_client.result.dig(:response)
          else
            @message = 'FieldPulse job not found'
            @result  = {}
            @success = false
          end

          @result
        end

        # list FieldPulse jobs
        # fp_model.jobs()
        #   (opt) page:  (Integer / default: 1)
        #   (opt) search: (String / default: nil)
        def jobs(**args)
          reset_attributes
          result = []
          page   = 1

          loop do
            @fp_client.jobs(page:, search: args.dig(:search).presence)

            if @fp_client.success?
              break unless @fp_client.result.dig(:response).is_a?(Array) && @fp_client.result.dig(:response).present?

              result += @fp_client.result.dig(:response)
              page   += 1
            else
              result = []

              break
            end
          end

          update_attributes_from_client

          @result = result
        end

        def datetime_from_webhook(contact, datetime)
          Time.use_zone(contact.client.time_zone) { Chronic.parse(datetime) }&.utc
        end
      end
    end
  end
end

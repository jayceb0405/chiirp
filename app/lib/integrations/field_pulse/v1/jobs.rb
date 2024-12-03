# frozen_string_literal: true

# app/lib/integrations/field_pulse/v1/jobs.rb
module Integrations
  module FieldPulse
    module V1
      module Jobs
        # call FieldPulse API for a specific job
        # fp_client.job()
        #   fp_job_id: (Integer)
        def job(fp_job_id)
          reset_attributes
          @result = {}

          if fp_job_id.to_i.zero?
            @message = 'Invalid FieldPulse job id'
            @success = false
            return @result
          end

          fieldpulse_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FieldPulse::V1::Jobs.job',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "jobs/#{fp_job_id}"
          )

          @result
        end
        # example FieldPulse response
        # {
        #   error:    false,
        #   response: {
        #     id:                                 8345173,
        #     company_id:                         114785,
        #     mongo_id:                           nil,
        #     cuid:                               1003,
        #     author_id:                          190917,
        #     customer_id:                        7796731,
        #     job_type:                           'Job for JimBob Martin',
        #     status:                             1,
        #     start_time:                         '2024-10-12 12:00:00',
        #     end_time:                           '2024-10-12 14:00:00',
        #     due_date:                           nil,
        #     billing:                            1,
        #     assignment_count:                   1,
        #     in_progress_status_log:             808,
        #     invoice_status:                     nil,
        #     notes:                              '',
        #     location_old:                       nil,
        #     location_coords:                    nil,
        #     tags_string:                        nil,
        #     created_at:                         '2024-10-09 19:06:23',
        #     updated_at:                         '2024-10-09 19:56:43',
        #     deleted_at:                         nil,
        #     project_id:                         nil,
        #     recurring_parent_id:                nil,
        #     upcoming_job_notified:              nil,
        #     detached_from_recurring_parent:     nil,
        #     maintenance_agreement_id:           nil,
        #     maintenance_occurrence_id:          nil,
        #     uuid:                               nil,
        #     field_notes:                        '',
        #     hazardco_swms_id:                   nil,
        #     service_titan_id:                   nil,
        #     service_titan_location_id:          nil,
        #     type:                               'job',
        #     task_category_id:                   nil,
        #     on_the_way_status_log:              165,
        #     is_template:                        false,
        #     template_id:                        nil,
        #     location_id:                        8399883,
        #     customer_contact_id:                nil,
        #     subtitle:                           '',
        #     import_id:                          nil,
        #     status_id:                          920838,
        #     status_workflow_id:                 173020,
        #     is_visible:                         true,
        #     nicejob_id:                         nil,
        #     completed_at:                       nil,
        #     customer_arrival_window_start_time: '2024-10-09 12:00:00',
        #     customer_arrival_window_end_time:   '2024-10-09 14:00:00',
        #     source:                             nil,
        #     status_log:                         { in_progress: 808, on_the_way: 165, pending: 0, completed: 0 },
        #     customfields:                       [],
        #     total_price:                        '0.00',
        #     has_available_forms:                false,
        #     tags:                               [],
        #     map:                                nil,
        #     customer_contact:                   nil,
        #     assignments:                        [{
        #       company_id:      114785,
        #       user_id:         190919,
        #       assignable_id:   8345173,
        #       assignable_type: 'App\\Http\\Api\\Core\\Models\\BaseJob',
        #       created_at:      '2024-10-09T19:51:48.000000Z',
        #       updated_at:      '2024-10-09T19:51:48.000000Z',
        #       team_id:         130453,
        #       mongo_id:        nil,
        #       id:              38770286
        #     }],
        #     customer:                           {
        #       id:                                    7796731,
        #       company_id:                            114785,
        #       mongo_id:                              nil,
        #       email:                                 'jimbob@asdf.org',
        #       phone:                                 '8021234567',
        #       city:                                  nil,
        #       state:                                 nil,
        #       notes:                                 '',
        #       address_1:                             nil,
        #       address_2:                             nil,
        #       cuid:                                  1003,
        #       first_name:                            'JimBob',
        #       middle_name:                           nil,
        #       last_name:                             'Martin',
        #       company_name:                          '',
        #       zip_code:                              nil,
        #       searchable:                            'JimBob Martin',
        #       sort_key:                              'jimbob martin',
        #       status:                                'current customer',
        #       has_different_billing_address:         false,
        #       alt_email:                             '',
        #       phone_e164:                            nil,
        #       qbo_id:                                nil,
        #       title:                                 nil,
        #       suffix:                                nil,
        #       alt_phone:                             '9125554568',
        #       billing_address_1:                     '',
        #       billing_address_2:                     '',
        #       billing_city:                          '',
        #       billing_state:                         '',
        #       fax:                                   '',
        #       skype:                                 '',
        #       assigned_to:                           190917,
        #       billing_zip_code:                      '',
        #       secondary_first_name:                  '',
        #       secondary_last_name:                   '',
        #       secondary_email:                       '',
        #       secondary_phone:                       '',
        #       use_company_name:                      nil,
        #       dial_phone:                            '',
        #       mobile_phone:                          '',
        #       website:                               '',
        #       qbo_sync_token:                        nil,
        #       last_qbo_sync:                         nil,
        #       created_at:                            '2024-10-02 15:14:12',
        #       updated_at:                            '2024-10-02 16:23:39',
        #       deleted_at:                            nil,
        #       parent_id:                             nil,
        #       postal_code:                           nil,
        #       alt_first_name:                        nil,
        #       alt_last_name:                         nil,
        #       lead_source:                           nil,
        #       service_address_1:                     nil,
        #       service_address_2:                     nil,
        #       service_address_city:                  nil,
        #       service_address_state:                 nil,
        #       service_address_zip_code:              nil,
        #       job_notes:                             '',
        #       account_type:                          'individual',
        #       parent_id_previous:                    nil,
        #       address1:                              nil,
        #       xero_id:                               nil,
        #       is_sync:                               nil,
        #       notes_old:                             nil,
        #       different_billing_address:             nil,
        #       xero_group_id:                         nil,
        #       dev_qbo:                               nil,
        #       source:                                nil,
        #       secondar_last_name:                    nil,
        #       sync_status:                           nil,
        #       xero_guid:                             nil,
        #       display_name:                          'JimBob Martin',
        #       uuid:                                  '5e6440f6-b527-4fd5-8dab-9b9661d60d94',
        #       xero_updated_date_utc:                 nil,
        #       country_code:                          'US',
        #       country_phone_code:                    'US',
        #       has_valid_phone:                       false,
        #       alt_phone_e164:                        '+19125554568',
        #       secondary_phone_e164:                  nil,
        #       searchable_number:                     '+19125554568',
        #       phone_validation_message:              'Number does not match the provided country.',
        #       lead_source_id:                        843250,
        #       servicerocketpro_id:                   nil,
        #       service_titan_id:                      nil,
        #       pipeline_status_id:                    nil,
        #       next_steps:                            '',
        #       qbd_id:                                nil,
        #       qbd_edit_sequence:                     nil,
        #       merged_customer_id:                    nil,
        #       pipeline_status_updated_at:            '2024-10-02 15:14:12',
        #       mailchimp_contact_id:                  nil,
        #       is_tax_exempt:                         false,
        #       qbo_tax_exempt_reason:                 nil,
        #       search_text:                           "'jimbob':2,4,6,8 'jimbob@asdf.org':1 'martin':3,5,7,9",
        #       import_id:                             nil,
        #       qbd_fullname:                          nil,
        #       qbd_addr_company_name:                 false,
        #       qbd_addr_first_last_name:              false,
        #       nicejob_id:                            nil,
        #       marketing360_id:                       nil,
        #       qbo_is_project:                        false,
        #       asset_display_settings:                {
        #         is_asset_company_header_visible:       true,
        #         is_asset_customer_header_visible:      true,
        #         is_asset_summary_visible:              true,
        #         is_asset_notes_visible:                true,
        #         is_asset_details_visible:              true,
        #         is_asset_warranty_information_visible: true,
        #         is_asset_conditional_visible:          true,
        #         asset_file_size:                       'large',
        #         asset_update_entity_mode:              'all',
        #         is_asset_updates_files_visible:        true,
        #         asset_update_file_size:                'large',
        #         is_asset_files_visible:                true,
        #         email_body_message:                    '',
        #         is_asset_custom_fields_visible:        true
        #       },
        #       next_sync_allowed_at:                  nil,
        #       sync_version:                          nil,
        #       job_display_settings:                  {
        #         is_job_company_header_visible:  true,
        #         is_job_customer_header_visible: true,
        #         is_job_summary_visible:         true,
        #         is_job_notes_visible:           true,
        #         is_job_custom_fields_visible:   true,
        #         is_job_field_notes_visible:     true,
        #         is_job_details_visible:         true,
        #         is_job_subtasks_visible:        true,
        #         is_job_visits_visible:          true,
        #         job_file_size:                  'large',
        #         is_job_files_visible:           true,
        #         is_folder_section_visible:      true,
        #         is_job_date_visible:            true,
        #         is_job_time_visible:            true,
        #         is_job_location_title_visible:  false
        #       },
        #       default_invoice_due_date:              nil,
        #       default_estimate_expiration_date:      nil,
        #       is_phone_notification_subscribed:      true,
        #       is_email_notification_subscribed:      true,
        #       billing_address_3:                     '',
        #       billing_address_4:                     '',
        #       billing_address_5:                     '',
        #       is_created_outside_franchise_category: false,
        #       tags:                                  [],
        #       customfields:                          []
        #     },
        #     entity_location:                    {
        #       id:                          8399883,
        #       company_id:                  114785,
        #       author_id:                   190917,
        #       object_id:                   7796731,
        #       object_type:                 'App\\Http\\Api\\Core\\Models\\BaseCustomer',
        #       title:                       'Main Location',
        #       address_1:                   '',
        #       address_2:                   '',
        #       city:                        '',
        #       state:                       '',
        #       zip_code:                    '',
        #       notes:                       '',
        #       is_main_location:            true,
        #       created_at:                  '2024-10-02 15:14:12',
        #       updated_at:                  '2024-10-02 15:14:12',
        #       deleted_at:                  nil,
        #       location_coords:             nil,
        #       order_index:                 1,
        #       is_primary_location:         true,
        #       primary_customer_contact_id: nil,
        #       search_text:                 '',
        #       import_id:                   nil,
        #       address_3:                   '',
        #       address_4:                   '',
        #       address_5:                   '',
        #       tax_rate:                    nil
        #     }
        #   }
        # }

        # call FieldPulse API for jobs
        # fp_client.jobs()
        #   (opt) limit: (Integer / default: Integrations::FieldPulse::V1::Base::IMPORT_BLOCK_COUNT)
        #   (opt) page:  (Integer / default: 1)
        #   (opt) search: (String / default: nil)
        def jobs(**args)
          reset_attributes
          @result = {}
          page    = (args.dig(:page) || 1).to_i

          params = {
            limit: (args.dig(:limit) || Integrations::FieldPulse::V1::Base::IMPORT_BLOCK_COUNT).to_i,
            page:
          }
          params[:search] = args[:search] if args.dig(:search).present?

          fieldpulse_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FieldPulse::V1::Jobs.jobs',
            method:                'get',
            params:,
            default_result:        @result,
            url:                   'jobs'
          )

          @result
        end
        # example FieldPulse response
        # {
        #   error:         false,
        #   total_results: 2,
        #   response:      [
        #     {
        #       id:                                 8345173,
        #       company_id:                         114785,
        #       mongo_id:                           nil,
        #       cuid:                               1003,
        #       author_id:                          190917,
        #       customer_id:                        7796731,
        #       job_type:                           'Job for JimBob Martin',
        #       status:                             1,
        #       start_time:                         '2024-10-12 12:00:00',
        #       end_time:                           '2024-10-12 14:00:00',
        #       due_date:                           nil,
        #       billing:                            1,
        #       assignment_count:                   1,
        #       in_progress_status_log:             808,
        #       invoice_status:                     nil,
        #       notes:                              '',
        #       location_old:                       nil,
        #       location_coords:                    nil,
        #       tags_string:                        nil,
        #       created_at:                         '2024-10-09 19:06:23',
        #       updated_at:                         '2024-10-09 19:56:43',
        #       deleted_at:                         nil,
        #       project_id:                         nil,
        #       recurring_parent_id:                nil,
        #       upcoming_job_notified:              nil,
        #       detached_from_recurring_parent:     nil,
        #       maintenance_agreement_id:           nil,
        #       maintenance_occurrence_id:          nil,
        #       uuid:                               nil,
        #       field_notes:                        '',
        #       hazardco_swms_id:                   nil,
        #       service_titan_id:                   nil,
        #       service_titan_location_id:          nil,
        #       type:                               'job',
        #       task_category_id:                   nil,
        #       on_the_way_status_log:              165,
        #       is_template:                        false,
        #       template_id:                        nil,
        #       location_id:                        8399883,
        #       customer_contact_id:                nil,
        #       subtitle:                           '',
        #       import_id:                          nil,
        #       status_id:                          920838,
        #       status_workflow_id:                 173020,
        #       is_visible:                         true,
        #       nicejob_id:                         nil,
        #       completed_at:                       nil,
        #       customer_arrival_window_start_time: '2024-10-09 12:00:00',
        #       customer_arrival_window_end_time:   '2024-10-09 14:00:00',
        #       source:                             nil,
        #       tags:                               [],
        #       assignments:                        [{
        #         company_id:      114785,
        #         user_id:         190919,
        #         assignable_id:   8345173,
        #         assignable_type: 'App\\Http\\Api\\Core\\Models\\BaseJob',
        #         created_at:      '2024-10-09T19:51:48.000000Z',
        #         updated_at:      '2024-10-09T19:51:48.000000Z',
        #         team_id:         130453,
        #         mongo_id:        nil,
        #         id:              38770286
        #       }]
        #     },...
        #   ]
        # }
      end
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :client_api_integration do
    client
    name { '' }

    # not sure this is a good way to go
    # probably easier and more clear to set this up in the only spec that will use it
    factory :client_api_integration_for_callrail do
      transient do
        campaign                { create :campaign }
        webhook_signature_token { SecureRandom.urlsafe_base64 }
      end

      target          { 'callrail' }
      webhook_api_key { SecureRandom.uuid }
      credentials     do
        {
          api_key:                 'asdf',
          webhook_signature_token:
        }
      end
      events do
        [
          {
            event_id:           'asg2435',
            name:               'asdf',
            account_company_id: 'asdf::COMdcdc6f0d953941e8bebbd8bf22a03662',
            call_types:         %w[abandoned missed],
            keywords:           %w[nope asdf nothing],
            include_tags:       %w[goodtag],
            exclude_tags:       %w[badtag],
            action:             {
              campaign_id: campaign.id
            }
          },
          {
            event_id:           'asg2435',
            name:               'asdf2',
            type:               'outbound_post_call',
            account_company_id: 'asdf::COMdcdc6f0d953941e8bebbd8bf22a03662',
            keywords:           %w[nope asdf nothing],
            include_tags:       %w[goodtag],
            exclude_tags:       %w[badtag],
            answered:           false,
            action:             {
              campaign_id: campaign.id
            }
          },
          {
            event_id:           'asrlakg7',
            type:               'form_submission',
            name:               'asdf3',
            account_company_id: 'asdf::COMdcdc6f0d953941e8bebbd8bf22a03662',
            form_names:         ['Address Form Test'],
            action:             {
              campaign_id: campaign.id
            }
          }
        ]
      end
    end

    factory :client_api_integration_for_cardx do
      transient do
        campaign { create :campaign }
      end

      webhook_header_token { SecureRandom.alphanumeric(20) }
      target          { 'cardx' }
      webhook_api_key { SecureRandom.uuid }
      account { 'asdf' }
      redirect { 'https://apple.com/' }

      events do
        [
          {
            event_id: 'asg2435',
            name:     'asdf',
            action:   {
              campaign_id: campaign.id
            }
          }
        ]
      end

      service_titan do
        {
          post_payments: true,
          payment_type:  1,
          comment:       'asdf'
        }
      end
    end

    factory :client_api_integration_for_email do
      transient do
        campaign { create :campaign }
      end

      target { 'email' }
      api_key { SecureRandom.uuid }
      inbound_username { 'asdf@chiirp.io' }
    end

    factory :client_api_integration_for_jobber do
      target { 'jobber' }
      data do
        {
          credentials: {
            version:       '20220915',
            expires_at:    3.hours.from_now.iso8601,
            access_token:  'asdfasdfasdfsadfasdf',
            refresh_token: 'asdfasdfsadf'
          }
        }
      end
    end

    factory :client_api_integration_for_servicetitan do
      target { 'servicetitan' }
      data do
        {
          notes:                          {
            textin:          true,
            push_notes:      true,
            textout_auto:    true,
            textout_manual:  true,
            textout_aiagent: true
          },
          events:                         {
            '2386': {
              status:                            'sold',
              tag_id:                            0,
              group_id:                          0,
              stage_id:                          0,
              job_types:                         [],
              range_max:                         1000,
              total_max:                         0,
              total_min:                         0,
              call_types:                        [],
              membership:                        [],
              new_status:                        [],
              action_type:                       'job_scheduled',
              campaign_id:                       309,
              ext_tech_ids:                      [],
              call_duration:                     60,
              customer_type:                     [],
              tag_ids_exclude:                   [],
              tag_ids_include:                   [],
              membership_types:                  [],
              business_unit_ids:                 [],
              stop_campaign_ids:                 [],
              orphaned_estimates:                false,
              membership_days_prior:             90,
              assign_contact_to_user:            false,
              start_date_changes_only:           false,
              membership_campaign_stop_statuses: []
            },
            '3534': {
              status:                     'open',
              tag_id:                     0,
              group_id:                   0,
              stage_id:                   0,
              job_types:                  [],
              range_max:                  10_000_000,
              total_max:                  10_000_000,
              total_min:                  0,
              call_types:                 [],
              membership:                 [],
              new_status:                 [],
              action_type:                'estimate',
              campaign_id:                30_626,
              ext_tech_ids:               [],
              call_duration:              60,
              customer_type:              [],
              tag_ids_exclude:            [],
              tag_ids_include:            [],
              membership_types:           [],
              business_unit_ids:          [
                293_169,
                293_675,
                293_676
              ],
              assign_contact_to_user:     false,
              start_date_changes_only:    false,
              membership_expiration_days: 90
            },
            '5109': {
              status:                            'open',
              tag_id:                            0,
              group_id:                          0,
              stage_id:                          0,
              job_types:                         [],
              range_max:                         1000,
              total_max:                         0,
              total_min:                         0,
              call_types:                        [],
              membership:                        [],
              new_status:                        [],
              action_type:                       'membership_expiration',
              campaign_id:                       0,
              ext_tech_ids:                      [],
              call_duration:                     60,
              customer_type:                     [],
              tag_ids_exclude:                   [],
              tag_ids_include:                   [],
              membership_types:                  [
                261_596,
                292_144,
                298_795,
                4_089_876,
                4_021_526,
                60_188_044,
                63_167_667,
                80_025_937,
                62_860_480,
                63_028_670
              ],
              business_unit_ids:                 [],
              membership_days_prior:             90,
              assign_contact_to_user:            false,
              start_date_changes_only:           false,
              membership_campaign_stop_statuses: []
            },
            '5174': {
              status:                  'sold',
              tag_id:                  0,
              group_id:                0,
              stage_id:                0,
              job_types:               [],
              range_max:               1_000_000,
              total_max:               1_000_000,
              total_min:               0,
              call_types:              [],
              membership:              [],
              new_status:              [],
              action_type:             'estimate',
              campaign_id:             30_627,
              ext_tech_ids:            [],
              call_duration:           60,
              customer_type:           [],
              tag_ids_exclude:         [],
              tag_ids_include:         [],
              business_unit_ids:       [],
              assign_contact_to_user:  false,
              start_date_changes_only: false
            },
            '5930': {
              status:                            'dismissed',
              tag_id:                            0,
              group_id:                          0,
              stage_id:                          0,
              job_types:                         [],
              range_max:                         1_000_000,
              total_max:                         1_000_000,
              total_min:                         0,
              call_types:                        [],
              membership:                        [],
              new_status:                        [],
              action_type:                       'estimate',
              campaign_id:                       0,
              ext_tech_ids:                      [],
              call_duration:                     60,
              customer_type:                     [],
              tag_ids_exclude:                   [],
              tag_ids_include:                   [],
              membership_types:                  [],
              business_unit_ids:                 [],
              stop_campaign_ids:                 [],
              orphaned_estimates:                true,
              membership_days_prior:             90,
              assign_contact_to_user:            false,
              start_date_changes_only:           false,
              membership_campaign_stop_statuses: []
            },
            '6383': {
              status:                            'sold',
              tag_id:                            0,
              group_id:                          0,
              stage_id:                          0,
              job_types:                         [],
              range_max:                         1000,
              total_max:                         0,
              total_min:                         0,
              call_types:                        [],
              membership:                        [
                'active'
              ],
              new_status:                        [],
              action_type:                       'membership_service_event',
              campaign_id:                       0,
              ext_tech_ids:                      [],
              call_duration:                     60,
              customer_type:                     [],
              tag_ids_exclude:                   [],
              tag_ids_include:                   [],
              membership_types:                  [
                4_143_236,
                62_859_829
              ],
              business_unit_ids:                 [
                96_977_464,
                120_939
              ],
              membership_days_prior:             90,
              assign_contact_to_user:            false,
              start_date_changes_only:           false,
              membership_campaign_stop_statuses: []
            },
            '7251': {
              status:                            'open',
              tag_id:                            0,
              group_id:                          0,
              stage_id:                          0,
              job_types:                         [],
              range_max:                         1000,
              total_max:                         0,
              total_min:                         0,
              call_types:                        [],
              membership:                        [],
              new_status:                        %w[
                in_progress
                hold
                canceled
              ],
              action_type:                       'job_status_changed',
              campaign_id:                       0,
              ext_tech_ids:                      [],
              call_duration:                     60,
              customer_type:                     [],
              tag_ids_exclude:                   [],
              tag_ids_include:                   [],
              membership_types:                  [],
              business_unit_ids:                 [],
              stop_campaign_ids:                 [],
              orphaned_estimates:                false,
              membership_days_prior:             90,
              assign_contact_to_user:            false,
              start_date_changes_only:           false,
              membership_campaign_stop_statuses: []
            },
            '9744': {
              status:                            'open',
              tag_id:                            0,
              group_id:                          0,
              stage_id:                          0,
              job_types:                         [],
              range_max:                         1_000_000,
              total_max:                         1_000_000,
              total_min:                         0,
              call_types:                        [],
              membership:                        [],
              new_status:                        [],
              action_type:                       'estimate',
              campaign_id:                       32_389,
              ext_tech_ids:                      [],
              call_duration:                     60,
              customer_type:                     [],
              tag_ids_exclude:                   [],
              tag_ids_include:                   [],
              membership_types:                  [],
              business_unit_ids:                 [
                120_943,
                120_956,
                120_958,
                120_959
              ],
              membership_days_prior:             90,
              assign_contact_to_user:            false,
              start_date_changes_only:           false,
              membership_campaign_stop_statuses: []
            }
          },
          import:                         {
            tag_id_0:                  0,
            group_id_0:                0,
            stage_id_0:                0,
            campaign_id_0:             0,
            tag_id_above_0:            0,
            tag_id_below_0:            0,
            group_id_above_0:          0,
            group_id_below_0:          0,
            stage_id_above_0:          0,
            stage_id_below_0:          0,
            campaign_id_above_0:       0,
            campaign_id_below_0:       391,
            stop_campaign_ids_0:       %w[
              135
              381
            ],
            stop_campaign_ids_above_0: [],
            stop_campaign_ids_below_0: [
              0
            ]
          },
          reports:                        [
            {
              id:          '1a22b615-91ac-47d6-a7e7-078e701dfcd3',
              name:        'My First Report',
              report_id:   65_746_024,
              parameters:  {
                To:              {
                  days:      '0',
                  time:      '9:00',
                  data_type: 'Date',
                  direction: 'past'
                },
                From:            {
                  days:      '7',
                  time:      '9:00',
                  data_type: 'Date',
                  direction: 'past'
                },
                DateType:        {
                  number:    0,
                  data_type: 'Number'
                },
                BusinessUnitIds: {
                  number:    [
                    96_977_464,
                    120_943
                  ],
                  data_type: 'Number'
                }
              },
              category_id: 'marketing'
            }
          ],
          employees:                      {
            '1299975':   0,
            '1299977':   0,
            '25203304':  0,
            '25203658':  0,
            '25203846':  0,
            '30029289':  0,
            '30051067':  0,
            '30174689':  0,
            '40505376':  0,
            '41813946':  0,
            '50308668':  0,
            '60893271':  0,
            '70222776':  0,
            '98489432':  0,
            '100414215': 0,
            '200684558': 0,
            '235879691': 0
          },
          credentials:                    {
            app_id:               '01',
            client_id:            'cid.40krj6ku6fd9sqz7uxd3poudd',
            tenant_id:            '224861743',
            access_token:         'eyJhbGciOiJSUzI1NiIsImtpZCI6IjYwNkZEM0Y3NzgxNzM4N0U3NjVDRTY5NkUxNzU0RTM3ODNBODU3MkJSUzI1NiIsInR5cCI6ImF0K2p3dCIsIng1dCI6IllHX1Q5M2dYT0g1MlhPYVc0WFZPTjRPb1Z5cyJ9.eyJuYmYiOjE3MDUzNjQxODgsImV4cCI6MTcwNTM2NTA4OCwiaXNzIjoiaHR0cHM6Ly9hdXRoLnNlcnZpY2V0aXRhbi5pbyIsImNsaWVudF9pZCI6ImNpZC40MGtyajZrdTZmZDlzcXo3dXhkM3BvdWRkIiwiYm9va2luZ19wcm92aWRlciI6InB3em5vZTd6ZzZ1eXo1b3Bwc2dubWZkaGMiLCJncHNfcHJvdmlkZXIiOiJOYXRpdmUiLCJyZXBvcnRfY2F0ZWdvcnkiOiJtYXJrZXRpbmciLCJ0ZW5hbnQiOiIyMjQ4NjE3NDMiLCJhcGlhcHBfaWQiOiJ6MjdlY2MyZXo4MHZiIiwib3duZXJfaWQiOiJ0ZW5hbnQtMjI0ODYxNzQzLWVudi1wcm9kIiwiZXh0X2RhdGFfZ3VpZCI6ImE4MGQ3MWVmLTQyYWQtNDE5Yi1iZGY1LTc2ZTFkMjRjNzNhOCIsImp0aSI6IkZFM0RFRTRBQ0FGMTcwOTBBQUU4NTk2MUE3MkIwMzU5IiwiaWF0IjoxNzA1MzY0MTg4LCJzY29wZSI6WyJ0bi5hY2MuaW52ZW50b3J5YWRqdXN0bWVudHM6ciIsInRuLmFjYy5pbnZlbnRvcnlhZGp1c3RtZW50czp3IiwidG4uYWNjLmludmVudG9yeWJpbGxzOnIiLCJ0bi5hY2MuaW52ZW50b3J5YmlsbHM6dyIsInRuLmFjYy5pbnZlbnRvcnlyZWNlaXB0czpyIiwidG4uYWNjLmludmVudG9yeXJlY2VpcHRzOnciLCJ0bi5hY2MuaW52ZW50b3J5dHJhbnNmZXJzOnIiLCJ0bi5hY2MuaW52ZW50b3J5dHJhbnNmZXJzOnciLCJ0bi5hY2MuaW52b2ljZXM6ciIsInRuLmFjYy5pbnZvaWNlczp3IiwidG4uYWNjLnBheW1lbnRzOnIiLCJ0bi5hY2MucGF5bWVudHM6dyIsInRuLmFjYy5wYXltZW50dGVybXM6ciIsInRuLmFjYy5wYXltZW50dGVybXM6dyIsInRuLmFjYy5wYXltZW50dHlwZXM6ciIsInRuLmFjYy5wYXltZW50dHlwZXM6dyIsInRuLmFjYy5wdXJjaGFzZW9yZGVyczpyIiwidG4uYWNjLnB1cmNoYXNlb3JkZXJzOnciLCJ0bi5hY2MucHVyY2hhc2VyZXR1cm5zOnIiLCJ0bi5hY2MucHVyY2hhc2VyZXR1cm5zOnciLCJ0bi5hY2MudGF4em9uZXM6ciIsInRuLmFjYy50YXh6b25lczp3IiwidG4uY3JtLmJvb2tpbmdzOnIiLCJ0bi5jcm0uYm9va2luZ3M6dyIsInRuLmNybS5jdXN0b21lcnM6ciIsInRuLmNybS5jdXN0b21lcnM6dyIsInRuLmNybS5sZWFkczpyIiwidG4uY3JtLmxlYWRzOnciLCJ0bi5jcm0ubG9jYXRpb25zOnIiLCJ0bi5jcm0ubG9jYXRpb25zOnciLCJ0bi5jcm0udGFnczpyIiwidG4uY3JtLnRhZ3M6dyIsInRuLmRpcy5hcHBvaW50bWVudGFzc2lnbm1lbnRzOnIiLCJ0bi5kaXMuYXBwb2ludG1lbnRhc3NpZ25tZW50czp3IiwidG4uZGlzLmNhcGFjaXR5OnIiLCJ0bi5kaXMuY2FwYWNpdHk6dyIsInRuLmRpcy5ncHNwaW5nczpyIiwidG4uZGlzLmdwc3BpbmdzOnciLCJ0bi5kaXMubm9uam9iYXBwb2ludG1lbnRzOnIiLCJ0bi5kaXMubm9uam9iYXBwb2ludG1lbnRzOnciLCJ0bi5kaXMudGVjaG5pY2lhbnNoaWZ0czpyIiwidG4uZGlzLnRlY2huaWNpYW5zaGlmdHM6dyIsInRuLmRpcy56b25lczpyIiwidG4uZGlzLnpvbmVzOnciLCJ0bi5lcXMuaW5zdGFsbGVkZXF1aXBtZW50OnIiLCJ0bi5lcXMuaW5zdGFsbGVkZXF1aXBtZW50OnciLCJ0bi5mcm0uam9iczpyIiwidG4uZnJtLmpvYnM6dyIsInRuLmludi5hZGp1c3RtZW50czpyIiwidG4uaW52LmFkanVzdG1lbnRzOnciLCJ0bi5pbnYucHVyY2hhc2VvcmRlcnM6ciIsInRuLmludi5wdXJjaGFzZW9yZGVyczp3IiwidG4uaW52LnB1cmNoYXNlb3JkZXJ0eXBlczpyIiwidG4uaW52LnB1cmNoYXNlb3JkZXJ0eXBlczp3IiwidG4uaW52LnJlY2VpcHRzOnIiLCJ0bi5pbnYucmVjZWlwdHM6dyIsInRuLmludi5yZXR1cm5zOnIiLCJ0bi5pbnYucmV0dXJuczp3IiwidG4uaW52LnRyYW5zZmVyczpyIiwidG4uaW52LnRyYW5zZmVyczp3IiwidG4uaW52LnRydWNrczpyIiwidG4uaW52LnRydWNrczp3IiwidG4uaW52LnZlbmRvcnM6ciIsInRuLmludi52ZW5kb3JzOnciLCJ0bi5pbnYud2FyZWhvdXNlczpyIiwidG4uaW52LndhcmVob3VzZXM6dyIsInRuLmpiY2UuY2FsbHJlYXNvbnM6ciIsInRuLmpiY2UuY2FsbHJlYXNvbnM6dyIsInRuLmpwbS5hcHBvaW50bWVudHM6ciIsInRuLmpwbS5hcHBvaW50bWVudHM6dyIsInRuLmpwbS5qb2JjYW5jZWxyZWFzb25zOnIiLCJ0bi5qcG0uam9iY2FuY2VscmVhc29uczp3IiwidG4uanBtLmpvYmhvbGRyZWFzb25zOnIiLCJ0bi5qcG0uam9iaG9sZHJlYXNvbnM6dyIsInRuLmpwbS5qb2JzOnIiLCJ0bi5qcG0uam9iczp3IiwidG4uanBtLmpvYnR5cGVzOnIiLCJ0bi5qcG0uam9idHlwZXM6dyIsInRuLmpwbS5wcm9qZWN0czpyIiwidG4uanBtLnByb2plY3RzOnciLCJ0bi5tYWRzLmV4dGVybmFsY2FsbGF0dHJpYnV0aW9uczpyIiwidG4ubWFkcy5leHRlcm5hbGNhbGxhdHRyaWJ1dGlvbnM6dyIsInRuLm1hZHMud2ViYm9va2luZ2F0dHJpYnV0aW9uczpyIiwidG4ubWFkcy53ZWJib29raW5nYXR0cmlidXRpb25zOnciLCJ0bi5tZW0uaW52b2ljZXRlbXBsYXRlczpyIiwidG4ubWVtLmludm9pY2V0ZW1wbGF0ZXM6dyIsInRuLm1lbS5tZW1iZXJzaGlwczpyIiwidG4ubWVtLm1lbWJlcnNoaXBzOnciLCJ0bi5tZW0ubWVtYmVyc2hpcHR5cGVzOnIiLCJ0bi5tZW0ubWVtYmVyc2hpcHR5cGVzOnciLCJ0bi5tZW0ucmVjdXJyaW5nc2VydmljZWV2ZW50czpyIiwidG4ubWVtLnJlY3VycmluZ3NlcnZpY2VldmVudHM6dyIsInRuLm1lbS5yZWN1cnJpbmdzZXJ2aWNlczpyIiwidG4ubWVtLnJlY3VycmluZ3NlcnZpY2VzOnciLCJ0bi5tZW0ucmVjdXJyaW5nc2VydmljZXR5cGVzOnIiLCJ0bi5tZW0ucmVjdXJyaW5nc2VydmljZXR5cGVzOnciLCJ0bi5tcmsuY2FtcGFpZ25zOnIiLCJ0bi5tcmsuY2FtcGFpZ25zOnciLCJ0bi5tcmsuY2F0ZWdvcmllczpyIiwidG4ubXJrLmNhdGVnb3JpZXM6dyIsInRuLm1yay5jb3N0czpyIiwidG4ubXJrLmNvc3RzOnciLCJ0bi5wYi5jYXRlZ29yaWVzOnIiLCJ0bi5wYi5jYXRlZ29yaWVzOnciLCJ0bi5wYi5kaXNjb3VudHNhbmRmZWVzOnIiLCJ0bi5wYi5kaXNjb3VudHNhbmRmZWVzOnciLCJ0bi5wYi5lcXVpcG1lbnQ6ciIsInRuLnBiLmVxdWlwbWVudDp3IiwidG4ucGIubWF0ZXJpYWxzOnIiLCJ0bi5wYi5tYXRlcmlhbHM6dyIsInRuLnBiLnByaWNlYm9vazpyIiwidG4ucGIucHJpY2Vib29rOnciLCJ0bi5wYi5zZXJ2aWNlczpyIiwidG4ucGIuc2VydmljZXM6dyIsInRuLnJwci5keW5hbWljdmFsdWVzZXRzOnIiLCJ0bi5ycHIuZHluYW1pY3ZhbHVlc2V0czp3IiwidG4ucnByLnJlcG9ydGNhdGVnb3JpZXM6ciIsInRuLnJwci5yZXBvcnRjYXRlZ29yaWVzOnciLCJ0bi5ycHIucmVwb3J0czpyIiwidG4ucnByLnJlcG9ydHM6dyIsInRuLnNhbC5lc3RpbWF0ZXM6ciIsInRuLnNhbC5lc3RpbWF0ZXM6dyIsInRuLnN0dC5idXNpbmVzc3VuaXRzOnIiLCJ0bi5zdHQuYnVzaW5lc3N1bml0czp3IiwidG4uc3R0LmVtcGxveWVlczpyIiwidG4uc3R0LmVtcGxveWVlczp3IiwidG4uc3R0LnRhZ3R5cGVzOnIiLCJ0bi5zdHQudGFndHlwZXM6dyIsInRuLnN0dC50ZWNobmljaWFuczpyIiwidG4uc3R0LnRlY2huaWNpYW5zOnciLCJ0bi50bGMuY2FsbHM6ciIsInRuLnRsYy5jYWxsczp3IiwidG4udHNtLmRhdGE6ciIsInRuLnRzbS5kYXRhOnciLCJ0bi50c20udGFza3M6ciIsInRuLnRzbS50YXNrczp3Il19.qakxpI3P1badg3ZJUZH64t6zQANRb2ajeyyBoWYyjJoqS-KfwQB-zIhfmAI7HO6C3ucFN37W8rFE8uSNLbEdXJPNLKI28KLA-5IkoUapdwqgAeDoot1dJ_Iv00AJjohCUcK3_TPKvV90CfuISJXIu1jRSpbighHjAGpIOpUN4RgmEx8nF9_kEtTjZy-zPXBw2V7ryoDMDgoLdzFbxQVNiSF7kd83jt81UfOczJnJJ4ZWfZPPOLVTUXewA3OGdDHAXn7m6cQly5HJOntKJNbtiENe0lvos2f2oLGDwSLBrF-UnqI_-YXkr6PZKDlqp5T-tThOxqWVMa6zz8PqMv-mhA',
            client_secret:        'cs1.tarwiauyslwbi35r1a2joc4jfodd1e3iyf2kewiw1x83yej8ro',
            access_token_expires: 1_705_365_088
          },
          push_contacts:                  [
            {
              id:                             '589c6fe5-4144-4ff2-99ad-e02cf15887e3',
              type:                           'Booking',
              tag_id:                         103_059,
              priority:                       '',
              campaign_id:                    101_274_675,
              job_type_id:                    0,
              customer_type:                  'Residential',
              booking_source:                 'Chiirp',
              business_unit_id:               0,
              booking_provider_id:            107_535_737,
              summary_client_custom_field_id: 4706
            },
            {
              id:               'dabd954b-5346-498d-a0d9-e8898927e1c4',
              type:             'Booking',
              tag_id:           0,
              priority:         'Low',
              campaign_id:      0,
              job_type_id:      0,
              customer_type:    'Residential',
              custom_field_id:  0,
              business_unit_id: 0
            }
          ],
          booking_fields:                 {},
          current_report:                 {
            created_at:         '2023-07-17T21:34:40.676Z',
            st_report_id:       65_746_024,
            st_category_id:     'marketing',
            st_report_criteria: {
              id:          65_746_024,
              name:        'Customer by Service',
              fields:      [
                {
                  name:     'Code',
                  label:    'Item Code',
                  dataType: 'String'
                },
                {
                  name:     'Description',
                  label:    'Item Description',
                  dataType: 'String'
                },
                {
                  name:     'ItemBusinessUnitName',
                  label:    'Item Business Unit',
                  dataType: 'String'
                },
                {
                  name:     'CustomerName',
                  label:    'Customer Name',
                  dataType: 'String'
                },
                {
                  name:     'InvoiceNumber',
                  label:    'Invoice Number',
                  dataType: 'String'
                },
                {
                  name:     'InvoiceDate',
                  label:    'Invoice Date',
                  dataType: 'Date'
                },
                {
                  name:     'CustomerType',
                  label:    'Customer Type',
                  dataType: 'String'
                },
                {
                  name:     'CustomerPhone',
                  label:    'Customer Phone',
                  dataType: 'String'
                },
                {
                  name:     'CustomerStreet',
                  label:    'Customer Street',
                  dataType: 'String'
                },
                {
                  name:     'CustomerCity',
                  label:    'Customer City',
                  dataType: 'String'
                },
                {
                  name:     'CustomerState',
                  label:    'Customer State',
                  dataType: 'String'
                },
                {
                  name:     'CustomerZip',
                  label:    'Customer Zip',
                  dataType: 'String'
                },
                {
                  name:     'Total',
                  label:    'Invoice Total',
                  dataType: 'Number'
                },
                {
                  name:     'AssignedTechnicians',
                  label:    'Assigned Technicians',
                  dataType: 'String'
                }
              ],
              modifiedOn:  '2023-05-10T13:16:40.635266-04:00',
              parameters:  [
                {
                  name:         'DateType',
                  label:        'Date Type',
                  isArray:      false,
                  dataType:     'Number',
                  isRequired:   true,
                  acceptValues: {
                    fields:       [
                      {
                        name:  'Value',
                        label: 'Value'
                      },
                      {
                        name:  'Name',
                        label: 'Name'
                      }
                    ],
                    values:       [
                      [
                        0,
                        'Completion Date'
                      ],
                      [
                        1,
                        'Invoice Date'
                      ],
                      [
                        2,
                        'Creation Date'
                      ],
                      [
                        3,
                        'Scheduled Date'
                      ]
                    ],
                    dynamicSetId: nil
                  }
                },
                {
                  name:         'From',
                  label:        'From',
                  isArray:      false,
                  dataType:     'Date',
                  isRequired:   true,
                  acceptValues: nil
                },
                {
                  name:         'To',
                  label:        'To',
                  isArray:      false,
                  dataType:     'Date',
                  isRequired:   true,
                  acceptValues: nil
                },
                {
                  name:         'BusinessUnitIds',
                  label:        'Invoice Item Business Unit',
                  isArray:      true,
                  dataType:     'Number',
                  isRequired:   false,
                  acceptValues: {
                    fields:       [
                      {
                        name:  'Value',
                        label: 'Value'
                      },
                      {
                        name:  'Name',
                        label: 'Name'
                      }
                    ],
                    values:       nil,
                    dynamicSetId: 'business-units'
                  }
                }
              ],
              description: 'Upgraded version of the legacy Customer by Service Report. Applying a column filter to the Item Name column will allow you to select a particular item in your pricebook and identify all customers who have been invoiced for that item. '
            }
          },
          tenant_api_key:                 '',
          customer_custom_fields:         {
            '20012431': 'Wintac Customer Number',
            '22311192': 'C/O'
          },
          update_balance_actions:         {
            tag_id_0:                         0,
            group_id_0:                       0,
            stage_id_0:                       0,
            campaign_id_0:                    0,
            tag_id_decrease:                  0,
            tag_id_increase:                  0,
            group_id_decrease:                0,
            group_id_increase:                0,
            stage_id_decrease:                0,
            stage_id_increase:                0,
            campaign_id_decrease:             0,
            campaign_id_increase:             0,
            update_balance_window_days:       0,
            update_invoice_window_days:       0,
            update_open_estimate_window_days: 30
          },
          custom_field_assignments:       {},
          ignore_sold_with_line_items:    [
            219_860_773,
            50_783_633
          ],
          imported_orphaned_estimates_at: '2023-05-23T06:04:43Z'
        }
      end
    end

    factory :client_api_integration_for_sendgrid do
      target { 'sendgrid' }
      api_key { 'asdf' }
    end
  end
end

# spec/lib/acceptable_time_spec.rb
# foreman run bundle exec rspec spec/models/integration/housecallpro/v1/housecallpro_spec.rb
require 'rails_helper'

RSpec.describe Integration::Housecallpro::V1::Base do
  let(:client) do
    User.transaction do
      user = User.new(
        firstname:    'Kevin',
        lastname:     'Neubert',
        phone:        '8023455136',
        email:        'kevin@kevinneubert.com',
        access_level: 10,
        provider:     'facebook',
        uid:          '2263573190337140',
        user_avatar:  '',
        data:         {
          'agent'                     => true,
          'phone_in'                  => '8023455136',
          'edit_tags'                 => true,
          'phone_out'                 => '8023455136',
          'edit_groups'               => true,
          'super_admin'               => true,
          'channel_open'              => true,
          'notifications'             => {
            'task' => {
              'due'       => false,
              'by_push'   => false,
              'by_text'   => false,
              'created'   => false,
              'updated'   => false,
              'deadline'  => false,
              'completed' => false
            },
            'text' => {
              'arrive'     => [3],
              'on_contact' => false
            },
            'review' => {
              'by_push'   => false,
              'by_text'   => false,
              'matched'   => false,
              'unmatched' => false
            }, 'agency_clients' => [4]
          },
          'ring_duration'             => 20,
          'channel_latest'            => 'users_central_206',
          'agency_user_token'         => '',
          'trainings_editable'        => [],
          'incoming_call_popup'       => true,
          'default_stage_parent'      => 2,
          'phone_in_with_action'      => false,
          'submit_text_on_enter'      => false,
          'version_notification'      => false,
          'default_stage_parent_id'   => 2,
          'current_controller_action' => 'dashboards_update_cal_tasks'
        },
        suspended_at: nil,
        ext_ref_id:   '',
        permissions:  { 'users_controller' => %w[allowed profile tasks phone_processing notifications admin_settings permissions], 'stages_controller' => %w[allowed all_contacts], 'central_controller' => %w[allowed all_contacts], 'clients_controller' => %w[allowed dlc10 billing custom_fields groups holidays kpis lead_sources org_chart phone_numbers profile stages statements tags task_actions terms users voice_recordings folder_assignments], 'surveys_controller' => ['allowed'], 'widgets_controller' => ['allowed'], 'campaigns_controller' => ['allowed'], 'companies_controller' => ['allowed'], 'dashboard_controller' => %w[allowed calendar company_tiles all_contacts tasks], 'trainings_controller' => ['allowed'], 'my_contacts_controller' => %w[allowed all_contacts], 'integrations_controller' => %w[client user google_messages google_reviews], 'import_contacts_controller' => ['allowed'], 'trackable_links_controller' => ['allowed'], 'user_contact_forms_controller' => ['allowed'], 'integrations_servicetitan_controller' => [] }
      )
      client = Client.new(
        name:            "Joe's Garage",
        address1:        'PO Box 263',
        address2:        '',
        city:            'Belmont',
        state:           'VT',
        zip:             '05730',
        phone:           '8023455136',
        time_zone:       'Eastern Time (US & Canada)',
        def_user:        user,
        current_balance: 6_067_515,
        next_pmt_date:   Chronic.parse('2023-01-12'),
        data:
                         { 'active'                                             => true,
                           'domains'                                            => {},
                           'training'                                           => %w[8 1],
                           'locked_at'                                          => nil,
                           'mo_charge'                                          => '400.0',
                           'setup_fee'                                          => '199.0',
                           'unlimited'                                          => false,
                           'card_brand'                                         => 'Visa',
                           'card_last4'                                         => '4242',
                           'card_token'                                         => 'tok_1L9DmJEo1z7FTBnwtvcsTo7l',
                           'mo_credits'                                         => '4000.0',
                           'package_id'                                         => 4,
                           'text_delay'                                         => 10,
                           'my_agencies'                                        => [4],
                           'rvm_allowed'                                        => true,
                           'rvm_credits'                                        => '4.0',
                           'client_token'                                       => 'cus_IXhMEHCfMX5s09',
                           'fp_affiliate'                                       => '',
                           'groups_count'                                       => 20,
                           'promo_months'                                       => 0,
                           'stages_count'                                       => 5,
                           'task_actions'                                       =>
                                                                                   { 'due'       => { 'tag_id' => 0, 'group_id' => 0, 'campaign_id' => 0 },
                                                                                     'assigned'  => { 'tag_id' => 0, 'group_id' => 0, 'campaign_id' => 0 },
                                                                                     'deadline'  => { 'tag_id' => 49, 'group_id' => 0, 'campaign_id' => 0 },
                                                                                     'completed' => { 'tag_id' => 0, 'group_id' => 0, 'campaign_id' => 0 } },
                           'agency_access'                                      => true,
                           'auto_recharge'                                      => true,
                           'card_exp_year'                                      => '2025',
                           'credit_charge'                                      => '0.02',
                           'folders_count'                                      => 3,
                           'surveys_count'                                      => 10,
                           'tasks_allowed'                                      => true,
                           'trial_credits'                                      => '0.0',
                           'widgets_count'                                      => 10,
                           'card_exp_month'                                     => '6',
                           'max_kpis_count'                                     => 10,
                           'terms_accepted'                                     => '2021-08-26T19:54:00Z',
                           'auto_add_amount'                                    => 1250,
                           'auto_min_amount'                                    => 250,
                           'campaigns_count'                                    => 100,
                           'max_users_count'                                    => 15,
                           'package_page_id'                                    => 1,
                           'promo_mo_charge'                                    => 0.0,
                           'reviews_allowed'                                    => false,
                           'promo_mo_credits'                                   => 0.0,
                           'max_phone_numbers'                                  => 5,
                           'my_dialer_allowed'                                  => false,
                           'quick_leads_count'                                  => 10,
                           'user_chat_allowed'                                  => true,
                           'max_contacts_count'                                 => -1,
                           'phone_call_credits'                                 => '2.0',
                           'text_image_credits'                                 => '1.0',
                           'video_call_credits'                                 => '3.0',
                           'custom_fields_count'                                => 50,
                           'my_contacts_allowed'                                => true,
                           'phone_calls_allowed'                                => true,
                           'promo_credit_charge'                                => 0.0,
                           'video_calls_allowed'                                => true,
                           'contact_phone_labels'                               => %w[main home work voice mobile office fax other],
                           'integrations_allowed'                               => [
                             'housecall'
                           ],
                           'max_voice_recordings'                               => 10,
                           'onboarding_scheduled'                               => '',
                           'scheduleonce_api_key'                               => '',
                           'share_stages_allowed'                               => true,
                           'text_message_credits'                               => '2.0',
                           'import_contacts_count'                              => 1000,
                           'mo_charge_retry_count'                              => 0,
                           'share_funnels_allowed'                              => true,
                           'share_surveys_allowed'                              => 'true',
                           'share_widgets_allowed'                              => true,
                           'subscriptions_allowed'                              => true,
                           'trackable_links_count'                              => 10,
                           'subscriptions_password'                             => '',
                           'message_central_allowed'                            => true,
                           'promo_max_phone_numbers'                            => 0,
                           'scheduleonce_webhook_id'                            => '',
                           'first_payment_delay_days'                           => 0,
                           'text_segment_charge_type'                           => 0,
                           'credit_charge_retry_level'                          => 1250,
                           'share_quick_leads_allowed'                          => true,
                           'first_payment_delay_months'                         => 0,
                           'text_message_images_allowed'                        => true,
                           'scheduleonce_booking_no_show'                       => 0,
                           'scheduleonce_booking_canceled'                      => 0,
                           'scheduleonce_booking_completed'                     => 0,
                           'scheduleonce_booking_scheduled'                     => 0,
                           'scheduleonce_booking_rescheduled'                   => 0,
                           'my_contacts_group_actions_all_allowed'              => true,
                           'scheduleonce_booking_canceled_then_rescheduled'     => 0,
                           'scheduleonce_booking_canceled_reschedule_requested' => 0 },
        contact_id:      0,
        tenant:          'chiirp',
        phone_vendor:    'sinch'
      )
      user.client = client
      user.skip_password_validation = true
      client.save!
      user.save!

      client
    end
  end
  let(:client_api_integration) do
    ClientApiIntegration.create!(
      client_id: client.id,
      target:    'housecall',
      name:      '',
      api_key:   'cc854ea54897f6776422351406445688bc148b50fca2ba6f7fbe8583c35ea278',
      data:      {
        'company'           => {
          'id'                     => 'c1f65771-82ea-4722-89df-6144317a30f2',
          'name'                   => 'Chiirp',
          'address'                => { 'zip' => '84604', 'city' => 'Provo', 'state' => 'UT', 'street' => '4833 Edgewood Dr', 'country' => 'US', 'latitude' => '40.2980219', 'longitude' => '-111.6610885', 'street_line_2' => '' },
          'website'                => 'http://CHIIRP.com',
          'logo_url'               => '',
          'time_zone'              => 'America/Denver',
          'phone_number'           => '9098065762',
          'support_email'          => 'ryan@chiirp.com',
          'default_arrival_window' => 0
        },
        'webhooks'          => {
          'job_created'                             => [
            {
              'actions'  => { 'tag_id' => 0, 'group_id' => 0, 'stage_id' => 0, 'assign_user' => false, 'campaign_id' => 0 },
              'criteria' => {
                'event_new'          => true,
                'line_items'         => ['olit_02c60923e5454022af0feb1c1c7bf240'],
                'ext_tech_ids'       => ['pro_6dfa336aa6be48a4bc5a6fd570304a2e'],
                'lead_sources'       => %w[5 1],
                'tech_updated'       => false,
                'event_updated'      => true,
                'approval_status'    => [],
                'tag_ids_exclude'    => [176],
                'tag_ids_include'    => [261],
                'start_date_updated' => 'false'
              },
              'event_id' => 'wrWzziBH80pYbhkmPpoq'
            }
          ],
          'job_on_my_way'                           => [
            {
              'actions'  => { 'tag_id' => 0, 'group_id' => 0, 'stage_id' => 0, 'assign_user' => false, 'campaign_id' => 0 },
              'criteria' => {
                'event_new'          => true,
                'line_items'         => [],
                'ext_tech_ids'       => [],
                'lead_sources'       => [],
                'tech_updated'       => false,
                'event_updated'      => true,
                'approval_status'    => [],
                'tag_ids_exclude'    => [],
                'tag_ids_include'    => [],
                'start_date_updated' => 'false'
              },
              'event_id' => '5gWbs1RFkQ3lNjxOa4RC'
            }
          ],
          'job_scheduled'                           => [
            {
              'actions'  => { 'tag_id' => 250, 'group_id' => 0, 'stage_id' => 0, 'assign_user' => false, 'campaign_id' => 0 },
              'criteria' => {
                'event_new'          => true,
                'line_items'         => [],
                'ext_tech_ids'       => [],
                'tech_updated'       => false,
                'event_updated'      => true,
                'approval_status'    => [],
                'tag_ids_exclude'    => [],
                'tag_ids_include'    => [],
                'start_date_updated' => 'false'
              },
              'event_id' => 'dduKmV5iBltNK491w5hc'
            }
          ],
          'customer_updated'                        => [
            {
              'actions'  => { 'tag_id' => 164, 'group_id' => 0, 'stage_id' => 0, 'assign_user' => false, 'campaign_id' => 0 },
              'criteria' => { 'line_items' => [], 'tag_ids_exclude' => [], 'tag_ids_include' => [] },
              'event_id' => '1pWNnnzWyERj6xTIJaR1'
            }
          ],
          'estimate_option_approval_status_changed' => [
            {
              'actions'  => { 'tag_id' => 0, 'group_id' => 0, 'stage_id' => 0, 'assign_user' => false, 'campaign_id' => 0 },
              'criteria' => {
                'event_new'          => false,
                'line_items'         => [],
                'tech_updated'       => false,
                'event_updated'      => false,
                'approval_status'    => [],
                'tag_ids_exclude'    => [],
                'tag_ids_include'    => [],
                'start_date_updated' => false
              },
              'event_id' => 'Ogp3w9limTkjKz2kPNJ4'
            }
          ]
        },
        'employees'         => {
          'pro_5a8c7237615a41b49157ce9f31748a26' => 0,
          'pro_6dfa336aa6be48a4bc5a6fd570304a2e' => 27,
          'pro_72c8ad8a2ad0478d84aa9214fa1e3f77' => 5,
          'pro_76d0a1ff8d174ce381d1e75f6bcf9e92' => 41,
          'pro_fac7f76b125b4315a2c0d1f2015360d0' => 28
        },
        'price_book'        => {
          ''                                       => { 'name' => nil, 'category' => nil },
          'olit_02c60923e5454022af0feb1c1c7bf240'  => { 'name' => 'Online Booking - Residential A/C Service Call', 'category' => 'Job' },
          'olit_067b26c268a5443a81c4dd07a5455a53'  => { 'name' => 'A/C Capacitor Replacement', 'category' => 'Job' },
          'pbmat_c777e85e435f4a62a1291218e5c9c827' => { 'name' => '1G Outlet or Switch Box', 'category' => 'Outlets' }
        },
        'custom_fields'     => {
          'invoice_id_hcp'               => 2412,
          'job_status_hcp'               => 3158,
          'estimate_id_hcp'              => 3159,
          'invoice_name_hcp'             => 2414,
          'invoice_total_hcp'            => 2416,
          'job_completed_hcp'            => 2963,
          'invoice_number_hcp'           => 2413,
          'estimate_number_hcp'          => 3160,
          'estimate_status_hcp'          => 3163,
          'invoice_balance_hcp'          => 2417,
          'job_technician_id_hcp'        => 2418,
          'estimate_completed_hcp'       => 3162,
          'invoice_description_hcp'      => 2415,
          'job_scheduled_start_hcp'      => 2962,
          'job_technician_name_hcp'      => 2419,
          'job_technician_email_hcp'     => 2961,
          'job_technician_phone_hcp'     => 2960,
          'estimate_scheduled_start_hcp' => 3161
        },
        'refresh_token'     => '3ce93331c28aec61a685d480cdd6cc2e8818cb8cdf07a57c4ea046e1e34a5bf8',
        'push_leads_tag_id' => 0
      }
    )
  end
  let(:chiirp_tag) do
    Tag.create!(
      name:        'Chiirp',
      client:,
      campaign_id: 0,
      group_id:    0,
      tag_id:      0,
      color:       '',
      stage_id:    0
    )
  end
  let(:main_tag) do
    Tag.create!(
      name:        'Main',
      client:,
      campaign_id: 0,
      group_id:    0,
      tag_id:      0,
      color:       '',
      stage_id:    0
    )
  end
  let(:master_tag) do
    Tag.create!(
      name:        'Master',
      client:,
      campaign_id: 0,
      group_id:    0,
      tag_id:      0,
      color:       '',
      stage_id:    0
    )
  end

  ##########
  # Integration::Housecallpro::V1::Base.new(client_api_integration).approval_status_matches?
  ##########
  [
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: [],                                expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: [nil],                             expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: %w[approved declined], expected: true },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['declined', nil],                 expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: [],                            event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro approved'],                  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined'],                      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro declined'],                  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: %w[approved declined], expected: true },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined', 'pro approved'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined', 'pro declined'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro approved', 'pro declined'],  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro approved', nil],             expected: false },

    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved'],                      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined'],                      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro declined'],                  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: %w[approved declined], expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved', 'pro declined'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined', 'pro declined'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved'],                      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro approved'],                  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro declined'],                  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved', 'pro approved'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: %w[approved declined], expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved', 'pro declined'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined', 'pro approved'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro approved', 'pro declined'],  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro approved', nil],             expected: false },

    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved'],                      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro approved'],                  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined'],                      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved', 'pro approved'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: %w[approved declined], expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved', 'pro declined'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined', 'pro approved'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro approved', 'pro declined'],  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro approved', nil],             expected: false },

    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved'],                      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro approved'],                  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined'],                      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro declined'],                  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: [nil],                             expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved', 'pro approved'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: %w[approved declined], expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved', 'pro declined'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined', 'pro approved'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined', 'pro declined'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro approved', 'pro declined'],  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro approved', nil],             expected: false },

    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined'],                      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro declined'],                  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: %w[approved declined], expected: true },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined', 'pro declined'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved'],                      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro approved'],                  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved', 'pro approved'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: %w[approved declined], expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved', 'pro declined'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined', 'pro approved'],      expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro approved', 'pro declined'],  expected: false },
    { event_name: 'estimate_option_approval_status_changed', criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro approved', nil],             expected: false },

    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: [],                                expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: [nil],                             expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: %w[approved declined], expected: true },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['declined', nil],                 expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: [],                            event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro approved'],                  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined'],                      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro declined'],                  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: %w[approved declined], expected: true },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined', 'pro approved'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined', 'pro declined'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro approved', 'pro declined'],  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro approved', nil],             expected: false },

    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved'],                      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined'],                      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro declined'],                  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: %w[approved declined], expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved', 'pro declined'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined', 'pro declined'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved'],                      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro approved'],                  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro declined'],                  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved', 'pro approved'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: %w[approved declined], expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved', 'pro declined'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined', 'pro approved'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro approved', 'pro declined'],  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro approved', nil],             expected: false },

    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved'],                      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro approved'],                  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined'],                      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved', 'pro approved'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: %w[approved declined], expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved', 'pro declined'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined', 'pro approved'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro approved', 'pro declined'],  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro approved', nil],             expected: false },

    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved'],                      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro approved'],                  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined'],                      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro declined'],                  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: [nil],                             expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved', 'pro approved'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: %w[approved declined], expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved', 'pro declined'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined', 'pro approved'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined', 'pro declined'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro approved', 'pro declined'],  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro approved', nil],             expected: false },

    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined'],                      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro declined'],                  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: %w[approved declined], expected: true },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined', 'pro declined'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: [],                                expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved'],                      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro approved'],                  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: [nil],                             expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved', 'pro approved'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: %w[approved declined], expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved', 'pro declined'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined', 'pro approved'],      expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined', nil],                 expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro approved', 'pro declined'],  expected: false },
    { event_name: 'estimate_sent',                           criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro approved', nil],             expected: false },

    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: [],                                expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: [nil],                             expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: %w[approved declined], expected: true },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['declined', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: [],                            event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: [],                                expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: [nil],                             expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: %w[approved declined], expected: true },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['declined', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved'],                  event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: [],                                expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: [nil],                             expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: %w[approved declined], expected: true },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['declined', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro approved'],              event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: [],                                expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: [nil],                             expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: %w[approved declined], expected: true },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['declined', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined'],                  event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: [],                                expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: [nil],                             expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: %w[approved declined], expected: true },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['declined', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['pro declined'],              event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: [],                                expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: [nil],                             expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: %w[approved declined], expected: true },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['declined', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['null'],                      event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: [],                                expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: [nil],                             expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: %w[approved declined], expected: true },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['declined', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['approved', 'pro approved'],  event_approval_statuses: ['pro approved', nil],             expected: true  },

    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: [],                                expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro approved'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined'],                      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro declined'],                  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: [nil],                             expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: %w[approved declined], expected: true },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['approved', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined', 'pro approved'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined', 'pro declined'],      expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['declined', nil],                 expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro approved', 'pro declined'],  expected: true  },
    { event_name: '',                                        criteria_approval_statuses: ['declined', 'pro declined'],  event_approval_statuses: ['pro approved', nil],             expected: true  }
  ].each do |x|
    it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).approval_status_matches?(#{x[:event_name]}, #{x[:criteria_approval_statuses]}, #{x[:event_approval_statuses]})" do
      expect(Integration::Housecallpro::V1::Base.new(client_api_integration).approval_status_matches?(x[:event_name], x[:criteria_approval_statuses], x[:event_approval_statuses])).to eq(x[:expected])
    end
  end

  ##########
  # Integration::Housecallpro::V1::Base.new(client_api_integration).ext_tech_ids_include?
  ##########
  [
    { criteria_ext_tech_ids: %w[asdf 1234 qwerty],  event_ext_tech_id: 'asdf',  expected: true },
    { criteria_ext_tech_ids: %w[asdf 1234 qwerty],  event_ext_tech_id: '1234',  expected: true },
    { criteria_ext_tech_ids: %w[asdf 1234 qwerty],  event_ext_tech_id: '', expected: false },
    { criteria_ext_tech_ids: %w[asdf 1234 qwerty],  event_ext_tech_id: 'qwse', expected: false },
    { criteria_ext_tech_ids: %w[], event_ext_tech_id: 'asdf', expected: true },
    { criteria_ext_tech_ids: %w[], event_ext_tech_id: '', expected: true }
  ].each do |x|
    %w[job_created job_canceled job_completed job_deleted job_on_my_way job_paid job_scheduled job_started job_appointment_scheduled job_appointment_rescheduled job_appointment_appointment_pros_assigned job_appointment_appointment_pros_unassigned job_appointment_appointment_discarded estimate_scheduled estimate_on_my_way estimate_copy_to_job estimate_sent estimate_completed estimate_option_created estimate_option_approval_status_changed].each do |event_name|
      it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).ext_tech_ids_include?(#{event_name}, #{x[:criteria_ext_tech_ids]}, #{x[:event_ext_tech_id]}})" do
        expect(Integration::Housecallpro::V1::Base.new(client_api_integration).ext_tech_ids_include?(event_name, x[:criteria_ext_tech_ids], x[:event_ext_tech_id])).to eq(x[:expected])
      end
    end

    %w[customer_created customer_updated customer_deleted].each do |event_name|
      it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).ext_tech_ids_include?(#{event_name}, #{x[:criteria_ext_tech_ids]}, #{x[:event_ext_tech_id]}})" do
        expect(Integration::Housecallpro::V1::Base.new(client_api_integration).ext_tech_ids_include?(event_name, x[:criteria_ext_tech_ids], x[:event_ext_tech_id])).to eq(true)
      end
    end
  end

  ##########
  # Integration::Housecallpro::V1::Base.new(client_api_integration).lead_sources_include?
  ##########
  [
    { criteria_lead_source_ids: %w[asdf 1234 qwerty],  event_lead_source_id: 'asdf',  expected: true },
    { criteria_lead_source_ids: %w[asdf 1234 qwerty],  event_lead_source_id: '1234',  expected: true },
    { criteria_lead_source_ids: %w[asdf 1234 qwerty],  event_lead_source_id: '', expected: false },
    { criteria_lead_source_ids: %w[asdf 1234 qwerty],  event_lead_source_id: 'qwse', expected: false },
    { criteria_lead_source_ids: %w[], event_lead_source_id: 'asdf', expected: true },
    { criteria_lead_source_ids: %w[], event_lead_source_id: '', expected: true }
  ].each do |x|
    it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).lead_sources_include?(#{x[:criteria_lead_source_ids]}, #{x[:event_lead_source_id]}})" do
      expect(Integration::Housecallpro::V1::Base.new(client_api_integration).lead_sources_include?(x[:criteria_lead_source_ids], x[:event_lead_source_id])).to eq(x[:expected])
    end
  end

  ##########
  # Integration::Housecallpro::V1::Base.new(client_api_integration).line_items_match?
  ##########
  [
    { criteria_line_items: %w[asdf 1234 qwerty],  event_line_items: %w[asdf 1234 qwerty], expected: true },
    { criteria_line_items: %w[asdf 1234 qwerty],  event_line_items: %w[asdf], expected: true },
    { criteria_line_items: %w[asdf 1234 qwerty],  event_line_items: %w[], expected: false },
    { criteria_line_items: %w[asdf 1234 qwerty],  event_line_items: %w[qwse fdsa 7890], expected: false },
    { criteria_line_items: %w[], event_line_items: %w[asdf 1234 qwerty],  expected: true },
    { criteria_line_items: %w[], event_line_items: %w[],  expected: true  }
  ].each do |x|
    %w[job_created job_canceled job_completed job_deleted job_on_my_way job_paid job_scheduled job_started job_appointment_scheduled job_appointment_rescheduled job_appointment_appointment_pros_assigned job_appointment_appointment_pros_unassigned job_appointment_appointment_discarded].each do |event_name|
      it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).line_items_match?(#{event_name}, #{x[:criteria_line_items]}, #{x[:event_line_items]}})" do
        expect(Integration::Housecallpro::V1::Base.new(client_api_integration).line_items_match?(event_name, x[:criteria_line_items], x[:event_line_items])).to eq(x[:expected])
      end
    end

    %w[customer_created customer_updated customer_deleted estimate_scheduled estimate_on_my_way estimate_copy_to_job estimate_sent estimate_completed estimate_option_created estimate_option_approval_status_changed].each do |event_name|
      it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).line_items_match?(#{event_name}, #{x[:criteria_line_items]}, #{x[:event_line_items]}})" do
        expect(Integration::Housecallpro::V1::Base.new(client_api_integration).line_items_match?(event_name, x[:criteria_line_items], x[:event_line_items])).to eq(true)
      end
    end
  end

  ##########
  # Integration::Housecallpro::V1::Base.new(client_api_integration).new_or_updated_event_match?
  ##########
  [
    { criteria_new: true,  criteria_updated: true,  event_new: true,  expected: true  },
    { criteria_new: true,  criteria_updated: true,  event_new: false, expected: true  },
    { criteria_new: true,  criteria_updated: false, event_new: true,  expected: true  },
    { criteria_new: true,  criteria_updated: false, event_new: false, expected: false },
    { criteria_new: false, criteria_updated: true,  event_new: true,  expected: false },
    { criteria_new: false, criteria_updated: true,  event_new: false, expected: true  },
    { criteria_new: false, criteria_updated: false, event_new: true,  expected: false },
    { criteria_new: false, criteria_updated: false, event_new: false, expected: false }
  ].each do |x|
    %w[job_created job_canceled job_completed job_deleted job_on_my_way job_paid job_scheduled job_started job_appointment_rescheduled estimate_scheduled estimate_on_my_way estimate_copy_to_job estimate_sent estimate_completed estimate_option_created estimate_option_approval_status_changed].each do |event_name|
      it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).new_or_updated_event_match?(#{event_name}, #{x[:criteria_new]}, #{x[:criteria_updated]}, #{x[:event_new]})" do
        expect(Integration::Housecallpro::V1::Base.new(client_api_integration).new_or_updated_event_match?(event_name, x[:criteria_new], x[:criteria_updated], x[:event_new])).to eq(x[:expected])
      end
    end

    %w[customer_created customer_updated customer_deleted job_appointment_appointment_pros_assigned job_appointment_appointment_pros_unassigned job_appointment_appointment_discarded].each do |event_name|
      it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).new_or_updated_event_match?(#{event_name}, #{x[:criteria_new]}, #{x[:criteria_updated]}, #{x[:event_new]})" do
        expect(Integration::Housecallpro::V1::Base.new(client_api_integration).new_or_updated_event_match?(event_name, x[:criteria_new], x[:criteria_updated], x[:event_new])).to eq(true)
      end
    end
  end

  ##########
  # Integration::Housecallpro::V1::Base.new(client_api_integration).start_date_updated?
  ##########
  {
    'job_created'                                 => true,
    'job_canceled'                                => true,
    'job_completed'                               => true,
    'job_deleted'                                 => true,
    'job_on_my_way'                               => true,
    'job_paid'                                    => true,
    'job_started'                                 => true,
    'job_appointment_scheduled'                   => true,
    'job_appointment_appointment_pros_assigned'   => true,
    'job_appointment_appointment_pros_unassigned' => true,
    'job_appointment_appointment_discarded'       => true,
    'customer_created'                            => true,
    'customer_updated'                            => true,
    'customer_deleted'                            => true,
    'estimate_created'                            => true,
    'estimate_on_my_way'                          => true,
    'estimate_copy_to_job'                        => true,
    'estimate_sent'                               => true,
    'estimate_completed'                          => true,
    'estimate_option_created'                     => true,
    'estimate_option_approval_status_changed'     => true
  }.each do |event, result|
    it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).start_date_updated?(#{event},  event_new: true,  event_start_date_updated: true)" do
      expect(Integration::Housecallpro::V1::Base.new(client_api_integration).start_date_updated?(event, true, true)).to eq(result)
    end

    it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).start_date_updated?(#{event},  event_new: true,  event_start_date_updated: false)" do
      expect(Integration::Housecallpro::V1::Base.new(client_api_integration).start_date_updated?(event, true, false)).to eq(result)
    end

    it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).start_date_updated?(#{event},  event_new: false,  event_start_date_updated: true)" do
      expect(Integration::Housecallpro::V1::Base.new(client_api_integration).start_date_updated?(event, false, true)).to eq(result)
    end

    it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).start_date_updated?(#{event},  event_new: false,  event_start_date_updated: false)" do
      expect(Integration::Housecallpro::V1::Base.new(client_api_integration).start_date_updated?(event, false, false)).to eq(result)
    end
  end
  # [event_new, event_start_date_updated]
  {
    'job_scheduled'               => [
      [true, true, true],
      [true, false, true],
      [false, true, true],
      [false, false, false]
    ],
    'estimate_scheduled'          => [
      [true, true, true],
      [true, false, true],
      [false, true, true],
      [false, false, false]
    ],
    'job_appointment_rescheduled' => [
      [true, true, true],
      [true, false, false],
      [false, true, true],
      [false, false, false]

    ]
  }.each do |event, result_array|
    result_array.each do |result|
      it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).start_date_updated?(#{event},  event_new: #{result[0]},  event_start_date_updated: #{result[1]})" do
        expect(Integration::Housecallpro::V1::Base.new(client_api_integration).start_date_updated?(event, result[0], result[1])).to eq(result[2])
      end
    end
  end

  ##########
  # Integration::Housecallpro::V1::Base.new(client_api_integration).tag_ids_exclude?
  ##########
  let(:test_examples_exclude) do
    [
      { criteria_tag_ids: [chiirp_tag.id, main_tag.id, master_tag.id],  event_tag_names: %w[Chiirp Main Master],  expected: false },
      { criteria_tag_ids: [chiirp_tag.id, main_tag.id, master_tag.id],  event_tag_names: %w[chiirp main master],  expected: true  },
      { criteria_tag_ids: [chiirp_tag.id, main_tag.id, master_tag.id],  event_tag_names: %w[Chiirp], expected: false },
      { criteria_tag_ids: [chiirp_tag.id, main_tag.id, master_tag.id],  event_tag_names: %w[Excel Frantic], expected: true },
      { criteria_tag_ids: [chiirp_tag.id, main_tag.id, master_tag.id],  event_tag_names: %w[], expected: true },
      { criteria_tag_ids: [], event_tag_names: %w[Excel Frantic], expected: true },
      { criteria_tag_ids: [], event_tag_names: %w[], expected: true }
    ]
  end
  it 'Test Integration::Housecallpro::V1::Base.new(client_api_integration).tag_ids_exclude?' do
    test_examples_exclude.each do |x|
      result = Integration::Housecallpro::V1::Base.new(client_api_integration).tag_ids_exclude?(x[:criteria_tag_ids], x[:event_tag_names])
      expect(result).to eq(x[:expected]), "expected #{x[:expected]}, got #{result} (#{x[:criteria_tag_ids]}, #{x[:event_tag_names]}})"
    end
  end

  ##########
  # Integration::Housecallpro::V1::Base.new(client_api_integration).tag_ids_include?
  ##########
  let(:test_examples_include) do
    [
      { criteria_tag_ids: [chiirp_tag.id, main_tag.id, master_tag.id],  event_tag_names: %w[Chiirp Main Master],  expected: true  },
      { criteria_tag_ids: [chiirp_tag.id, main_tag.id, master_tag.id],  event_tag_names: %w[chiirp main master],  expected: false },
      { criteria_tag_ids: [chiirp_tag.id, main_tag.id, master_tag.id],  event_tag_names: %w[Chiirp], expected: true },
      { criteria_tag_ids: [chiirp_tag.id, main_tag.id, master_tag.id],  event_tag_names: %w[Excel Frantic], expected: false },
      { criteria_tag_ids: [chiirp_tag.id, main_tag.id, master_tag.id],  event_tag_names: %w[], expected: false },
      { criteria_tag_ids: [], event_tag_names: %w[Excel Frantic], expected: true },
      { criteria_tag_ids: [], event_tag_names: %w[], expected: true }
    ]
  end
  it 'Test Integration::Housecallpro::V1::Base.new(client_api_integration).tag_ids_include?' do
    test_examples_include.each do |x|
      result = Integration::Housecallpro::V1::Base.new(client_api_integration).tag_ids_include?(x[:criteria_tag_ids], x[:event_tag_names])
      expect(result).to eq(x[:expected]), "expected #{x[:expected]}, got #{result} (#{x[:criteria_tag_ids]}, #{x[:event_tag_names]}})"
    end
  end

  ##########
  # Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?
  ##########
  #   {
  #     'job_created'                                 => true,
  #     'job_canceled'                                => true,
  #     'job_completed'                               => true,
  #     'job_deleted'                                 => true,
  #     'job_on_my_way'                               => true,
  #     'job_paid'                                    => true,
  #     'job_scheduled'                               => true,
  #     'job_started'                                 => true,
  #     'job_appointment_scheduled'                   => true,
  #     'job_appointment_rescheduled'                 => true,
  #     'job_appointment_appointment_pros_assigned'   => true,
  #     'job_appointment_appointment_pros_unassigned' => true,
  #     'job_appointment_appointment_discarded'       => true,
  #     'customer_created'                            => true,
  #     'customer_updated'                            => true,
  #     'customer_deleted'                            => true,
  #     'estimate_created'                            => true,
  #     'estimate_scheduled'                          => true,
  #     'estimate_on_my_way'                          => true,
  #     'estimate_copy_to_job'                        => true,
  #     'estimate_sent'                               => true,
  #     'estimate_completed'                          => true,
  #     'estimate_option_created'                     => true,
  #     'estimate_option_approval_status_changed'     => true
  #   }.each do |event|
  #     # (event_name, criteria_event_updated, criteria_tech_updated, event_new, event_tech_updated, expected)
  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, true, true, true, true, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], true, true, true, true)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, true, true, true, false, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], true, true, true, false)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, true, true, false, true, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], true, true, false, true)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, true, false, true, true, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], true, false, true, true)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, true, false, true, false, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], true, false, true, false)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, true, false, false, true, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], true, false, false, true)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, true, false, false, false, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], true, false, false, false)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, false, true, true, true, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], false, true, true, true)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, false, true, true, false, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], false, true, true, false)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, false, true, false, true, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], false, true, false, true)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, false, true, false, false, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], false, true, false, false)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, false, false, true, true, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], false, false, true, true)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, false, false, true, false, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], false, false, true, false)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, false, false, false, true, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], false, false, false, true)).to eq(event[1])
  #     end

  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, false, false, false, false, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], false, false, false, false)).to eq(event[1])
  #     end
  #   end

  #   {
  #     'job_created'                                 => true,
  #     'job_canceled'                                => true,
  #     'job_completed'                               => true,
  #     'job_deleted'                                 => true,
  #     'job_on_my_way'                               => true,
  #     'job_paid'                                    => true,
  #     'job_scheduled'                               => false,
  #     'job_started'                                 => true,
  #     'job_appointment_scheduled'                   => true,
  #     'job_appointment_rescheduled'                 => false,
  #     'job_appointment_appointment_pros_assigned'   => false,
  #     'job_appointment_appointment_pros_unassigned' => false,
  #     'job_appointment_appointment_discarded'       => true,
  #     'customer_created'                            => true,
  #     'customer_updated'                            => true,
  #     'customer_deleted'                            => true,
  #     'estimate_created'                            => true,
  #     'estimate_scheduled'                          => false,
  #     'estimate_on_my_way'                          => true,
  #     'estimate_copy_to_job'                        => true,
  #     'estimate_sent'                               => true,
  #     'estimate_completed'                          => true,
  #     'estimate_option_created'                     => true,
  #     'estimate_option_approval_status_changed'     => true
  #   }.each do |event|
  #     # (event_name, criteria_event_updated, criteria_tech_updated, event_new, event_tech_updated, expected)
  #     it "Test Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(#{event[0]}, true, true, false, false, #{event[1]})" do
  #       expect(Integration::Housecallpro::V1::Base.new(client_api_integration).tech_updated?(event[0], true, true, false, false)).to eq(event[1])
  #     end
  #   end
end

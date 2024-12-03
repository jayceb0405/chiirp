# frozen_string_literal: true

# app/helpers/application_helper.rb
module ApplicationHelper
  # ApplicationController.helpers.xxx

  # create an array of Canadian states suitable for options_for
  # canada_states_array
  def canada_states_array
    [
      %w[Alberta AB],
      ['British Columbia', 'BC'],
      %w[Manitoba MB],
      ['New Brunswick', 'NB'],
      ['Newfoundland and Labrador', 'NL'],
      ['Northwest Territories', 'NT'],
      ['Nova Scotia', 'NS'],
      %w[Nunavut NU],
      %w[Ontario ON],
      ['Prince Edward Island', 'PE'],
      %w[Quebec QC],
      %w[Saskatchewan SK],
      ['Yukon Territory', 'YT']
    ]
  end

  def ext_references_options(client)
    response = []

    response << ['Dope Marketing', 'dope_marketing'] if client.integrations_allowed.include?('dope_marketing')
    response << %w[Dropfunnels dropfunnels] if client.integrations_allowed.include?('dropfunnels')
    response << %w[FieldPulse fieldpulse] if client.integrations_allowed.include?('fieldpulse')
    response << %w[FieldRoutes fieldroutes] if client.integrations_allowed.include?('fieldroutes')
    response << ['Housecall Pro', 'housecallpro'] if client.integrations_allowed.include?('housecall')
    response << %w[Jobber jobber] if client.integrations_allowed.include?('jobber')
    response << %w[JobNimbus jobnimbus] if client.integrations_allowed.include?('jobnimbus')
    response << %w[Outreach outreach] if client.integrations_allowed.include?('outreach')
    response << ['PC Richard', 'pcrichard'] if client.integrations_allowed.include?('pcrichard')
    response << %w[ResponsiBid responsibid] if client.integrations_allowed.include?('responsibid')
    response << %w[SalesRabbit salesrabbit] if client.integrations_allowed.include?('salesrabbit')
    response << %w[SendJim sendjim] if client.integrations_allowed.include?('sendjim')
    response << %w[ServiceMonster servicemonster] if client.integrations_allowed.include?('servicemonster')
    response << %w[ServiceTitan servicetitan] if client.integrations_allowed.include?('servicetitan')
    response << %w[Successware successware] if client.integrations_allowed.include?('successware')
    response << %w[Thumbtack thumbtack] if client.integrations_allowed.include?('thumbtack')
    response << %w[Webhook webhook] if client.integrations_allowed.include?('webhook')
    response << %w[Zapier zapier] if client.integrations_allowed.include?('zapier')

    response
  end

  def home_page?
    controller_name == 'welcome' && controller.action_name == 'index'
  end

  def navbar_home_link
    tag.li(link_to('Home', root_path, class: 'nav-link'), class: 'nav-item d-none d-sm-inline-block') unless home_page?
  end

  def navbar_pushmenu(sidebar)
    tag.li(link_to(tag.i(class: 'fa fa-bars'), root_path, class: 'nav-link'), { class: 'nav-item', data: { widget: 'pushmenu' } }) if sidebar
  end

  # create options for a dropdown Campaign menu
  # options_for_campaign(client: Client)
  def options_for_campaign(args = {})
    if args.dig(:grouped).to_bool
      grouped_options_for_select(options_for_campaign_array(args), (args.dig(:selected_campaign_id) || 0))
    else
      options_for_select(options_for_campaign_array(args), (args.dig(:selected_campaign_id) || 0))
    end
  end

  # create options for a dropdown Campaign menu
  # options_for_campaign(client: Client)
  def options_for_campaign_array(args = {})
    client                    = args.dig(:client)
    exclude_campaigns         = [args.dig(:exclude_campaigns) || []].flatten
    first_trigger_types       = [args.dig(:first_trigger_types) || [115, 120, 125, 130, 133, 134, 135, 136, 137, 138, 139, 140, 145]].flatten
    sort_order                = (args.dig(:sort_order) || 'name').to_s
    add_options               = args.dig(:add_options) || []
    include_groups            = args.dig(:include_groups).to_bool
    grouped                   = args.dig(:grouped).to_bool
    include_analyzed          = args.dig(:include_analyzed).to_bool
    active_only               = args.dig(:active_only).to_bool
    campaigns_to_be_destroyed = DelayedJob.where(user_id: client.users.pluck(:id), process: 'campaign_destroy').map { |c| c.data.dig('campaign_id') }.compact_blank
    response                  = []

    if client.is_a?(Client)
      campaign_groups = include_groups ? client.campaign_groups.order(:name).pluck(:name, :id).map { |group| ["Group: #{group[0]}", "group_#{group[1]}"] } : []

      if grouped
        campaign_ids = Campaign.for_select(client.id, sort_order, (exclude_campaigns + campaigns_to_be_destroyed), first_trigger_types)
        campaign_ids = campaign_ids.active_only if active_only
        campaigns    = Campaign.where(id: campaign_ids.pluck(:name, :id).map(&:second)).left_outer_joins(:campaign_group).order('campaign_groups.name, campaigns.name').pluck('campaigns.id, campaigns.name, campaigns.campaign_group_id, campaign_groups.name, campaigns.analyzed')

        options = ['Ungrouped', []]

        (add_options.is_a?(Array) ? add_options : []).each do |option|
          options[1] << if include_analyzed
                          [option[0], option[1], true]
                        else
                          [option[0], option[1]]
                        end
        end

        campaign_groups.each do |option|
          options[1] << if include_analyzed
                          [option[0], option[1], true]
                        else
                          [option[0], option[1]]
                        end
        end

        campaigns.select { |campaign| campaign[3].nil? }.each do |option|
          options[1] << if include_analyzed
                          [option[1], option[0], option[4]]
                        else
                          [option[1], option[0]]
                        end
        end

        response          = [options]
        options           = ['', []]
        campaign_group_id = 0

        campaigns.reject { |campaign| campaign[3].nil? }.each do |option|
          unless campaign_group_id == option[2]
            response << options unless options[1].empty?
            options           = [option[3], []]
            campaign_group_id = option[2]
          end

          options[1] << if include_analyzed
                          [option[1], option[0], option[4]]
                        else
                          [option[1], option[0]]
                        end
        end

        response << options unless options[1].empty?
      else
        response = add_options if add_options.is_a?(Array)

        response = if include_analyzed
                     response.concat(campaign_groups).concat(Campaign.for_select(client.id, sort_order, exclude_campaigns, first_trigger_types).pluck(:name, :id, :analyzed))
                   else
                     response.concat(campaign_groups).concat(Campaign.for_select(client.id, sort_order, exclude_campaigns, first_trigger_types).pluck(:name, :id))
                   end
      end
    end

    response
  end

  def options_for_client_custom_fields(client, selected = 0)
    options_from_collection_for_select(client.client_custom_fields.order(:var_name), 'id', 'var_name', selected)
  end

  def options_for_ext_references(client, selected = '')
    options_for_select(ext_references_options(client), selected)
  end

  def options_for_group(client, selected, skip_groups, create_new)
    options_for_select(client.group_collection_options(create_new, skip_groups), selected)
  end

  # options_for_hashtag(client: Client)
  # (req) client:                        (Client)
  # (opt) include_estimate_hashtags:     (Boolean)
  # (opt) include_invoice_hashtags:      (Boolean)
  # (opt) include_job_hashtags:          (Boolean)
  # (opt) include_subscription_hashtags: (Boolean)
  # (opt) include_yield_tag:             (Boolean)
  def options_for_hashtag(args)
    # rubocop:disable Lint/InterpolationCheck
    {
      'Contact Company Name' => '#{contact-company-name}',
      'First Name'           => '#{firstname}',
      'Last Name'            => '#{lastname}',
      'Full Name'            => '#{fullname}',
      'Address 1'            => '#{address1}',
      'Address 2'            => '#{address2}',
      'City'                 => '#{city}',
      'State'                => '#{state}',
      'Zip Code'             => '#{zipcode}',
      'Email'                => '#{email}'
    }
      .merge(args.dig(:include_yield_tag) ? {
               'Custom Email Section' => '#{custom_email_section}'
             } : {})
      .merge(args.dig(:client).contact_phone_labels.to_h { |label| ["#{label.capitalize} Phone Number", "\#{phone-#{label}}"] })
      .merge({
               'User First Name'    => '#{a-firstname}',
               'User Last Name'     => '#{a-lastname}',
               'User Full Name'     => '#{a-fullname}',
               'User Phone'         => '#{a-phone}',
               'User Default Phone' => '#{a-default-phone}',
               'User Email'         => '#{a-email}',
               'My Company Name'    => '#{my-company-name}'
             })
      .merge(options_for_hashtag_custom_fields(args.dig(:client)))
      .merge(options_for_hashtag_fieldroutes(args.dig(:client), args.dig(:include_job_hashtags), args.dig(:include_subscription_hashtags)))
      .merge(options_for_hashtag_google(args.dig(:client)))
      .merge(options_for_hashtag_housecall(args.dig(:client), args.dig(:include_estimate_hashtags), args.dig(:include_job_hashtags)))
      .merge(options_for_hashtag_jobber(args.dig(:client), args.dig(:include_estimate_hashtags), args.dig(:include_invoice_hashtags), args.dig(:include_job_hashtags)))
      .merge(options_for_hashtag_jobnimbus(args.dig(:client), args.dig(:include_estimate_hashtags), args.dig(:include_job_hashtags)))
      .merge(options_for_hashtag_responsibid(args.dig(:client), args.dig(:include_estimate_hashtags)))
      .merge(options_for_hashtag_servicemonster(args.dig(:client), args.dig(:include_estimate_hashtags), args.dig(:include_job_hashtags)))
      .merge(options_for_hashtag_servicetitan(args.dig(:client), args.dig(:include_estimate_hashtags), args.dig(:include_job_hashtags)))
      .merge(options_for_hashtag_cardx(args.dig(:client)))
      .merge(args.dig(:client).surveys_count.to_i.positive? ? args.dig(:client).surveys.pluck(:id, :name).to_h { |id, name| ["#{name.gsub(%r{[^0-9A-Za-z ]}, '')} Survey", "\#{survey_link_#{id}}"] } : {})
      .merge(args.dig(:client).trackable_links_count.to_i.positive? ? args.dig(:client).trackable_links.pluck(:id, :name).to_h { |id, name| ["#{name.gsub(%r{[^0-9A-Za-z ]}, '')} Link", "\#{trackable_link_#{id}}"] } : {})
      .merge({
               'Reply STOP to opt out' => '#{opt_out}',
               'Todays Date'           => '#{today}',
               'Todays Date Extended'  => '#{today_ext}'
             })
      .merge({
               'User External Reference ID' => '#{user_ext_ref_id}'
             })
      .merge(ApplicationController.helpers.ext_references_options(args.dig(:client)).to_h { |e| ["Contact #{e[0]} ID", "\#{contact-#{e[1]}-id}"] })
    # rubocop:enable Lint/InterpolationCheck
  end

  def cardx_hashtags_allowed?(client)
    return false unless client.integrations_allowed.include?('cardx')
    return false unless (client_api_integration = client.client_api_integrations.find_by(target: 'cardx', name: '')) && Integrations::CardX::Base.new(client_api_integration.account).valid_credentials?

    true
  end

  def options_for_hashtag_cardx(client)
    return {} unless cardx_hashtags_allowed?(client)

    # rubocop:disable Lint/InterpolationCheck
    { 'Request Payment Link (CardX)' => '#{request_payment_link}' }
    # rubocop:enable Lint/InterpolationCheck
  end

  def options_for_hashtag_custom_fields(client)
    {}
      .merge(client.client_custom_fields.pluck(:var_var, :var_name, :var_type).to_h { |var| [var[1].delete('\''), "\#{#{var[0]}}"] })
      .merge(client.client_custom_fields.where(var_type: 'currency').pluck(:var_var, :var_name, :var_type).to_h { |var| ["#{var[1].delete('\'')} in Text", "\#{#{var[0]}_in_text}"] })
  end

  def options_for_hashtag_fieldroutes(client, include_job_hashtags, include_subscription_hashtags)
    return {} unless client.integrations_allowed.include?('fieldroutes')

    # rubocop:disable Lint/InterpolationCheck
    {}
      .merge(include_subscription_hashtags.to_bool ? {
               'Subscription Status (FR)'       => '#{subscription-status}',
               'Subscription First Name (FR)'   => '#{subscription-firstname}',
               'Subscription Last Name (FR)'    => '#{subscription-lastname}',
               'Subscription Full Name (FR)'    => '#{subscription-fullname}',
               'Subscription Company Name (FR)' => '#{subscription-companyname}',
               'Subscription Total (FR)'        => '#{subscription-total}',
               'Subscription Total Due (FR)'    => '#{subscription-total_due}',
               'Subscription Description (FR)'  => '#{subscription-description}'
             } : {})
      .merge(include_job_hashtags.to_bool ? {
               'Job Description (FR)'          => '#{job-description}',
               'Job Scheduled Start Date (FR)' => '#{job-scheduled_start_at}',
               'Job Scheduled End Date (FR)'   => '#{job-scheduled_end_at}',
               'Job Total (FR)'                => '#{job-total_amount}',
               'Date of Last Job (FR)'         => '#{job-last_date}',
               'Time Since Last Job (FR)'      => '#{job-time_since_last_date}'
             } : {})
      .merge(include_job_hashtags.to_bool ? {
               'Job Street Address (FR)' => '#{job-address}',
               'Job City (FR)'           => '#{job-city}',
               'Job State (FR)'          => '#{job-state}',
               'Job Postal Code (FR)'    => '#{job-postal_code}'
             } : {})
      .merge(include_job_hashtags.to_bool ? {
               'Technician ID (FR)'           => '#{tech-id}',
               'Technician Name (FR)'         => '#{tech-name}',
               'Technician First Name (FR)'   => '#{tech-firstname}',
               'Technician Phone Number (FR)' => '#{tech-phone}',
               'Technician Email (FR)'        => '#{tech-email}'
             } : {})
    # rubocop:enable Lint/InterpolationCheck
  end

  def options_for_hashtag_google(client)
    return {} unless client.integrations_allowed.include?('google')

    google_reviews_count_options = {}
    google_reviews_stars_options = {}
    google_reviews_link_options  = {}

    if (client_api_integration = client.client_api_integrations.find_by(target: 'google', name: '')) &&
       (user_api_integration = UserApiIntegration.find_by(user_id: client_api_integration.user_id, target: 'google', name: '')) && Integration::Google.valid_token?(user_api_integration)

      ggl_client = Integrations::Ggl::Base.new(user_api_integration.token, I18n.t('tenant.id'))

      client_api_integration.active_locations_reviews.each do |account, locations|
        locations.each do |location|
          google_location_title = (client_api_integration.active_locations_names&.dig(location).presence || ggl_client.my_business_location(location)&.dig(:title).to_s).truncate(20)

          google_reviews_count_options["Google Reviews Count - #{google_location_title}"] = "\#{google-reviews_count_#{account.split('/').last}_#{location.split('/').last}}"
          google_reviews_stars_options["Google Reviews Stars - #{google_location_title}"] = "\#{google-reviews_stars_#{account.split('/').last}_#{location.split('/').last}}"
          google_reviews_link_options["Google Reviews Link - #{google_location_title}"]   = "\#{google-reviews_link_#{account.split('/').last}_#{location.split('/').last}}"
        end
      end
    end

    # rubocop:disable Lint/InterpolationCheck
    {}
      .merge(google_reviews_count_options).merge(google_reviews_stars_options).merge(google_reviews_link_options)
      .merge({ 'Google Review Stars (Contact)' => '#{google-reviews_contact_stars}' })
    # rubocop:enable Lint/InterpolationCheck
  end

  def options_for_hashtag_housecall(client, include_estimate_hashtags, include_job_hashtags)
    return {} unless client.integrations_allowed.include?('housecall')

    # rubocop:disable Lint/InterpolationCheck
    {}
      .merge(include_estimate_hashtags.to_bool ? {
               'Estimate Number (HCP)'                        => '#{estimate-estimate_number}',
               'Estimate Status (HCP)'                        => '#{estimate-status}',
               'Estimate Scheduled Start Date (HCP)'          => '#{estimate-scheduled_start_at}',
               'Estimate Scheduled End Date (HCP)'            => '#{estimate-scheduled_end_at}',
               'Estimate Scheduled Arrival Window Date (HCP)' => '#{estimate-scheduled_arrival_window_date}',
               'Estimate Scheduled Arrival Window Time (HCP)' => '#{estimate-scheduled_arrival_window_time}',
               'Estimate Started Date (HCP)'                  => '#{estimate-actual_started_at}',
               'Estimate Completed Date (HCP)'                => '#{estimate-actual_completed_at}',
               'Estimate On My Way Date (HCP)'                => '#{estimate-actual_on_my_way_at}',
               'Date of Last Estimate (HCP)'                  => '#{estimate-last_date}',
               'Time Since Last Estimate (HCP)'               => '#{estimate-time_since_last_date}'
             } : {})
      .merge(include_job_hashtags.to_bool ? {
               'Job Invoice Number (HCP)'                => '#{job-invoice_number}',
               'Job Status (HCP)'                        => '#{job-status}',
               'Job Description (HCP)'                   => '#{job-description}',
               'Job Scheduled Start Date (HCP)'          => '#{job-scheduled_start_at}',
               'Job Scheduled End Date (HCP)'            => '#{job-scheduled_end_at}',
               'Job Scheduled Arrival Window Date (HCP)' => '#{job-scheduled_arrival_window_date}',
               'Job Scheduled Arrival Window Time (HCP)' => '#{job-scheduled_arrival_window_time}',
               'Job Started Date (HCP)'                  => '#{job-actual_started_at}',
               'Job Completed Date (HCP)'                => '#{job-actual_completed_at}',
               'Job On My Way Date (HCP)'                => '#{job-actual_on_my_way_at}',
               'Job Total (HCP)'                         => '#{job-total_amount}',
               'Job Balance (HCP)'                       => '#{job-outstanding_balance}',
               'Date of Last Job (HCP)'                  => '#{job-last_date}',
               'Time Since Last Job (HCP)'               => '#{job-time_since_last_date}'
             } : {})
      .merge(include_estimate_hashtags.to_bool || include_job_hashtags.to_bool ? {
               'Technician ID (HCP)'           => '#{tech-id}',
               'Technician Name (HCP)'         => '#{tech-name}',
               'Technician First Name (HCP)'   => '#{tech-firstname}',
               'Technician Phone Number (HCP)' => '#{tech-phone}',
               'Technician Email (HCP)'        => '#{tech-email}',
               'Technician Image (HCP)'        => '#{tech-image}'
             } : {})
      .merge(include_job_hashtags.to_bool ? {
               'Job Street Address (HCP)' => '#{job-address}',
               'Job City (HCP)'           => '#{job-city}',
               'Job State (HCP)'          => '#{job-state}',
               'Job Postal Code (HCP)'    => '#{job-postal_code}'
             } : {})
      .merge(include_job_hashtags.to_bool && cardx_hashtags_allowed?(client) ? {
               'Job Payment Request (HCP)'      => '#{job-payment_request}',
               'Job Remaining Amount Due (HCP)' => '#{job-remaining_amount_due}',
               'Job Total Amount Paid (HCP)'    => '#{job-total_amount_paid}'
             } : {})
    # rubocop:enable Lint/InterpolationCheck
  end

  def options_for_hashtag_jobber(client, include_estimate_hashtags, include_invoice_hashtags, include_job_hashtags)
    return {} unless client.integrations_allowed.include?('jobber')

    # rubocop:disable Lint/InterpolationCheck
    {}
      .merge(include_estimate_hashtags.to_bool ? {
               'Quote Number (JB)' => '#{estimate-estimate_number}',
               'Quote Status (JB)' => '#{estimate-status}'
             } : {})
      .merge(include_invoice_hashtags.to_bool ? {
               'Invoice Number (JB)'        => '#{invoice-invoice_number}',
               'Invoice Status (JB)'        => '#{invoice-status}',
               'Invoice Subject (JB)'       => '#{invoice-description}',
               'Invoice Total (JB)'         => '#{invoice-total_amount}',
               'Invoice Payments Made (JB)' => '#{invoice-total_payments}',
               'Invoice Balance Due (JB)'   => '#{invoice-balance_due}',
               'Invoice Due Date (JB)'      => '#{invoice-due_date}',
               'Invoice Net (JB)'           => '#{invoice-net}'
             } : {})
      .merge(include_job_hashtags.to_bool ? {
               'Job Invoice Number (JB)'                => '#{job-invoice_number}',
               'Job Status (JB)'                        => '#{job-status}',
               'Job Title (JB)'                         => '#{job-description}',
               'Job Scheduled Start Date (JB)'          => '#{job-scheduled_start_at}',
               'Job Scheduled End Date (JB)'            => '#{job-scheduled_end_at}',
               'Job Scheduled Arrival Window Date (JB)' => '#{job-scheduled_arrival_window_date}',
               'Job Scheduled Arrival Window Time (JB)' => '#{job-scheduled_arrival_window_time}',
               'Job Total (JB)'                         => '#{job-total_amount}',
               'Job Remaining Amount Due (JB)'          => '#{job-remaining_amount}',
               'Date of Last Job (JB)'                  => '#{job-last_date}',
               'Time Since Last Job (JB)'               => '#{job-time_since_last_date}'
             } : {})
      .merge(include_job_hashtags.to_bool ? {
               'Visit Status (JB)'     => '#{visit-status}',
               'Visit Start Date (JB)' => '#{visit-start_at}',
               'Visit End Date (JB)'   => '#{visit-end_at}'
             } : {})
      .merge(include_estimate_hashtags.to_bool || include_job_hashtags.to_bool ? {
               'Technician ID (JB)'           => '#{tech-id}',
               'Technician Name (JB)'         => '#{tech-name}',
               'Technician First Name (JB)'   => '#{tech-firstname}',
               'Technician Phone Number (JB)' => '#{tech-phone}',
               'Technician Email (JB)'        => '#{tech-email}',
               'Technician Image (JB)'        => '#{tech-image}'
             } : {})
      .merge(include_job_hashtags.to_bool && cardx_hashtags_allowed?(client) ? {
               'Job Payment Request (JB)'      => '#{job-payment_request}',
               'Job Remaining Amount Due (JB)' => '#{job-remaining_amount_due}',
               'Job Total Amount Paid (JB)'    => '#{job-total_amount_paid}'
             } : {})
    # rubocop:enable Lint/InterpolationCheck
  end

  def options_for_hashtag_jobnimbus(client, include_estimate_hashtags, include_job_hashtags)
    return {} unless client.integrations_allowed.include?('jobnimbus')

    # rubocop:disable Lint/InterpolationCheck
    {}
      .merge(include_estimate_hashtags.to_bool ? {
               'Estimate Number (JN)'               => '#{estimate-estimate_number}',
               'Estimate Status (JN)'               => '#{estimate-status}',
               'Estimate Sales Rep Name (JN)'       => '#{estimate-rep_name}',
               'Estimate Sales Rep Email (JN)'      => '#{estimate-rep_email}',
               'Estimate Scheduled Start Date (JN)' => '#{estimate-scheduled_start_at}',
               'Estimate Scheduled End Date (JN)'   => '#{estimate-scheduled_end_at}'
             } : {})
      .merge(include_job_hashtags.to_bool ? {
               'Work Order Invoice Number (JN)'       => '#{job-invoice_number}',
               'Work Order Status (JN)'               => '#{job-status}',
               'Work Order Description (JN)'          => '#{job-description}',
               'Work Order Sales Rep Name (JN)'       => '#{job-rep_name}',
               'Work Order Sales Rep Email (JN)'      => '#{job-rep_email}',
               'Work Order Scheduled Start Date (JN)' => '#{job-scheduled_start_at}',
               'Work Order Scheduled End Date (JN)'   => '#{job-scheduled_end_at}'
             } : {})
      .merge(include_job_hashtags.to_bool && cardx_hashtags_allowed?(client) ? {
               'Job Payment Request (JN)'      => '#{job-payment_request}',
               'Job Remaining Amount Due (JN)' => '#{job-remaining_amount_due}',
               'Job Total Amount Paid (JN)'    => '#{job-total_amount_paid}'
             } : {})
    # rubocop:enable Lint/InterpolationCheck
  end

  def options_for_hashtag_responsibid(client, include_estimate_hashtags)
    return {} unless client.integrations_allowed.include?('responsibid')

    # rubocop:disable Lint/InterpolationCheck
    {}
      .merge(include_estimate_hashtags.to_bool ? {
               'Estimate Status (RB)'                        => '#{estimate-status}',
               'Estimate Scheduled Start Date (RB)'          => '#{estimate-scheduled_start_at}',
               'Estimate Scheduled End Date (RB)'            => '#{estimate-scheduled_end_at}',
               'Estimate Scheduled Arrival Window Date (RB)' => '#{estimate-scheduled_arrival_window_date}',
               'Estimate Scheduled Arrival Window Time (RB)' => '#{estimate-scheduled_arrival_window_time}',
               'Estimate Proposal Link (RB)'                 => '#{estimate-proposal_url}'
             } : {})
    # rubocop:enable Lint/InterpolationCheck
  end

  def options_for_hashtag_servicemonster(client, include_estimate_hashtags, include_job_hashtags)
    return {} unless client.integrations_allowed.include?('servicemonster')

    # rubocop:disable Lint/InterpolationCheck
    {}
      .merge(include_estimate_hashtags.to_bool ? {
               'Estimate Number (SM)'                        => '#{estimate-estimate_number}',
               'Estimate Status (SM)'                        => '#{estimate-status}',
               'Estimate Scheduled Start Date (SM)'          => '#{estimate-scheduled_start_at}',
               'Estimate Scheduled Arrival Window Date (SM)' => '#{estimate-scheduled_arrival_window_date}',
               'Estimate Scheduled Arrival Window Time (SM)' => '#{estimate-scheduled_arrival_window_time}',
               'Estimate Scheduled End Date (SM)'            => '#{estimate-scheduled_end_at}',
               'Estimate Started Date (SM)'                  => '#{estimate-actual_started_at}',
               'Estimate Completed Date (SM)'                => '#{estimate-actual_completed_at}',
               'Estimate Total (SM)'                         => '#{estimate-total_amount}',
               'Estimate Balance (SM)'                       => '#{estimate-outstanding_balance}'
             } : {})
      .merge(include_job_hashtags.to_bool ? {
               'Order Invoice Number (SM)'                => '#{job-invoice_number}',
               'Order Status (SM)'                        => '#{job-status}',
               'Order Scheduled Start Date (SM)'          => '#{job-scheduled_start_at}',
               'Order Scheduled Arrival Window Date (SM)' => '#{job-scheduled_arrival_window_date}',
               'Order Scheduled Arrival Window Time (SM)' => '#{job-scheduled_arrival_window_time}',
               'Order Scheduled End Date (SM)'            => '#{job-scheduled_end_at}',
               'Order Started Date (SM)'                  => '#{job-actual_started_at}',
               'Order Completed Date (SM)'                => '#{job-actual_completed_at}',
               'Order Total (SM)'                         => '#{job-total_amount}',
               'Order Balance (SM)'                       => '#{job-outstanding_balance}'
             } : {})
      .merge(include_estimate_hashtags.to_bool || include_job_hashtags.to_bool ? {
               'Technician ID (SM)'           => '#{tech-id}',
               'Technician Name (SM)'         => '#{tech-name}',
               'Technician First Name (SM)'   => '#{tech-firstname}',
               'Technician Phone Number (SM)' => '#{tech-phone}',
               'Technician Email (SM)'        => '#{tech-email}',
               'Technician Image (SM)'        => '#{tech-image}'
             } : {})
      .merge(include_estimate_hashtags.to_bool || include_job_hashtags.to_bool ? {
               'Site Street Address (SM)' => '#{site-address}',
               'Site City (SM)'           => '#{site-city}',
               'Site State (SM)'          => '#{site-state}',
               'Site Postal Code (SM)'    => '#{site-postal_code}'
             } : {})
      .merge(include_job_hashtags.to_bool && cardx_hashtags_allowed?(client) ? {
               'Job Payment Request (SM)'      => '#{job-payment_request}',
               'Job Remaining Amount Due (SM)' => '#{job-remaining_amount_due}',
               'Job Total Amount Paid (SM)'    => '#{job-total_amount_paid}'
             } : {})
    # rubocop:enable Lint/InterpolationCheck
  end

  def options_for_hashtag_servicetitan(client, include_estimate_hashtags, include_job_hashtags)
    return {} unless client.integrations_allowed.include?('servicetitan')

    # rubocop:disable Lint/InterpolationCheck
    {}
      .merge(include_estimate_hashtags.to_bool ? {
               'Estimate Number (ST)'                        => '#{estimate-estimate_number}',
               'Estimate Status (ST)'                        => '#{estimate-status}',
               'Estimate Scheduled Start Date (ST)'          => '#{estimate-scheduled_start_at}',
               'Estimate Scheduled Arrival Window Date (ST)' => '#{estimate-scheduled_arrival_window_date}',
               'Estimate Scheduled End Date (ST)'            => '#{estimate-scheduled_end_at}',
               'Estimate Total (ST)'                         => '#{estimate-total_amount}'
             } : {})
      .merge(include_job_hashtags.to_bool ? {
               'Job Invoice Number (ST)'                => '#{job-invoice_number}',
               'Job Status (ST)'                        => '#{job-status}',
               'Job Scheduled Start Date (ST)'          => '#{job-scheduled_start_at}',
               'Job Scheduled End Date (ST)'            => '#{job-scheduled_end_at}',
               'Job Scheduled Arrival Window Date (ST)' => '#{job-scheduled_arrival_window_date}',
               'Job Scheduled Arrival Window Time (ST)' => '#{job-scheduled_arrival_window_time}',
               'Job Total (ST)'                         => '#{job-total_amount}',
               'Job Balance (ST)'                       => '#{job-outstanding_balance}',
               'Job Business Unit Name (ST)'            => '#{job-business_unit_name}'
             } : {})
      .merge(include_estimate_hashtags.to_bool || include_job_hashtags.to_bool ? {
               'Technician ID (ST)'           => '#{tech-id}',
               'Technician Name (ST)'         => '#{tech-name}',
               'Technician First Name (ST)'   => '#{tech-firstname}',
               'Technician Phone Number (ST)' => '#{tech-phone}',
               'Technician Email (ST'         => '#{tech-email}',
               'Technician Image (ST)'        => '#{tech-image}'
             } : {})
      .merge(include_estimate_hashtags.to_bool || include_job_hashtags.to_bool ? {
               'Site Street Address (ST)' => '#{site-address}',
               'Site City (ST)'           => '#{site-city}',
               'Site State (ST)'          => '#{site-state}',
               'Site Postal Code (ST)'    => '#{site-postal_code}'
             } : {})
      .merge(include_job_hashtags.to_bool && cardx_hashtags_allowed?(client) ? {
               'Job Payment Request (ST)'      => '#{job-payment_request}',
               'Job Remaining Amount Due (ST)' => '#{job-remaining_amount_due}',
               'Job Total Amount Paid (ST)'    => '#{job-total_amount_paid}'
             } : {})
    # rubocop:enable Lint/InterpolationCheck
  end

  # options_for_hashtag_string(client: Client, include_estimate_hashtags: Boolean, include_job_hashtags: Boolean)
  # (req) client:                    (Client)
  # (opt) include_estimate_hashtags: (Boolean)
  # (opt) include_job_hashtags:      (Boolean)
  def options_for_hashtag_string(args)
    options_for_hashtag(args).map { |k, v| "{username: '#{v.sub('#', '')}',name: '#{k}'}" }.to_s.delete('"')
  end

  def options_for_integrations
    (UserApiIntegration.integrations_array + ClientApiIntegration.integrations_array).sort
  end

  def options_for_lead_source(client, selected)
    options_for_select([['No Lead Source', 0]] + client.lead_sources.order(name: :asc).pluck(:name, :id), selected.presence)
  end

  def options_for_package(package_page, selected)
    packages = []

    if package_page
      package  = package_page.package_01
      packages << [package.name, package.id] if package
      package  = package_page.package_02
      packages << [package.name, package.id] if package
      package  = package_page.package_03
      packages << [package.name, package.id] if package
      package  = package_page.package_04
      packages << [package.name, package.id] if package
    end

    options_for_select(packages, selected)
  end

  def options_for_package_page(selected)
    options_for_select(PackagePage.pluck(:name, :id), selected)
  end

  def options_for_affiliate(selected)
    options_for_select(Affiliates::Affiliate.pluck(:company_name, :id), selected)
  end

  # return an Array of phone number options suitable for select
  #   [["Name", "0000000000"], ["Name", "0000000000"], ["Name", "0000000000"]]
  # options_for_phone_numbers(client: Client, selected: String, options: Array)
  # options_for_phone_numbers(user: User, selected: String, options: Array)
  # options_for_phone_numbers(contact: Contact, selected: String, options: Array)
  def options_for_phone_numbers(args = {})
    selected = args.dig(:selected) || []

    options_for_select(options_for_phone_numbers_array(args), selected:)
  end

  # return an Array of phone number options suitable for select
  #   [["Name", "0000000000"], ["Name", "0000000000"], ["Name", "0000000000"]]
  # options_for_phone_numbers(client: Client, selected: String, options: Array)
  # options_for_phone_numbers(user: User, selected: String, options: Array)
  # options_for_phone_numbers(contact: Contact, selected: String, options: Array)
  def options_for_phone_numbers_array(args = {})
    client       = args.dig(:client)
    user         = args.dig(:user)
    contact      = args.dig(:contact)
    options      = args.dig(:options) || []
    current_user = args.dig(:current_user)

    if client.is_a?(Client)
      options.to_h.merge(Twnumber.client_phone_numbers(client.id).pluck(:phonenumber, :name).to_h).map { |k, v| [(v.to_s.present? ? v : number_to_phone(k, { area_code: true })), k] }
    elsif user.is_a?(User)
      options.to_h.merge(Twnumber.user_phone_numbers(user.id).pluck(:phonenumber, :name).to_h).map { |k, v| [(v.to_s.present? ? v : number_to_phone(k, { area_code: true })), k] }
    elsif contact.is_a?(Contact) && current_user.is_a?(User)
      # called only from central/conversation/header
      (([['All Methods', 'all']] + options.to_h.merge(Twnumber.contact_phone_numbers(contact.id).pluck(:phonenumber, :name).to_h).merge(Twnumber.user_phone_numbers(contact.user.id).pluck(:phonenumber, :name).to_h).merge(Twnumber.user_phone_numbers(current_user.id).pluck(:phonenumber, :name).to_h).map { |k, v| [(v.to_s.present? ? v : number_to_phone(k, { area_code: true })), k] }) << (current_user.client.integrations_allowed.include?('facebook_messenger') ? ['Facebook Messenger', 'fb'] : []) << (current_user.client.integrations_allowed.include?('google') ? ['Google Messages', 'ggl'] : []) << (current_user.client.send_emails? ? %w[Email email] : [])).compact_blank
    elsif contact.is_a?(Contact)
      options.to_h.merge(Twnumber.contact_phone_numbers(contact.id).pluck(:phonenumber, :name).to_h).merge(Twnumber.user_phone_numbers(contact.user.id).pluck(:phonenumber, :name).to_h).map { |k, v| [(v.to_s.present? ? v : number_to_phone(k, { area_code: true })), k] }
    else
      options
    end
  end

  def options_for_phone_vendor(selected)
    options_for_select([
                         %w[Bandwidth bandwidth],
                         %w[Sinch sinch],
                         %w[Twilio twilio]
                       ], selected)
  end

  def options_for_tag(client, selected, skip_tags, create_new)
    options_for_select(client.tag_collection_options(create_new, skip_tags), selected)
  end

  def options_for_stage(client_id, selected_id)
    grouped_collection_select(:stage, :id, StageParent.where(client: client_id), :stages, :name, :id, :name, { selected: selected_id, include_blank: 'Select a Stage' })
  end

  # create options_for_select for states
  # options_for_state( country: ["US", "CA"], selected: String )
  def options_for_state(args = {})
    country   = [args.dig(:country) || ['us']].flatten.map(&:downcase)
    selected  = args.dig(:selected).to_s.upcase

    if (country.include?('us') || country.include?('usa')) && (country.include?('ca') || country.include?('canada'))
      grouped_options_for_select([['United States', us_states_array], ['Canada', canada_states_array]], selected)
    elsif country.include?('us') || country.include?('usa')
      options_for_select(us_states_array, selected)
    elsif country.include?('ca') || country.include?('canada')
      options_for_select(canada_states_array, selected)
    end
  end

  def options_for_dynamic_dates(selected)
    options_for_select(Users::Dashboards::Dashboard::DYNAMIC_DATES_ARRAY, selected)
  end

  # create an array of US states suitable for options_for
  # us_states_array
  def us_states_array
    [
      %w[Alabama AL],
      %w[Alaska AK],
      %w[Arizona AZ],
      %w[Arkansas AR],
      %w[California CA],
      %w[Colorado CO],
      %w[Connecticut CT],
      %w[Delaware DE],
      ['District Of Columbia', 'DC'],
      %w[Florida FL],
      %w[Georgia GA],
      %w[Hawaii HI],
      %w[Idaho ID],
      %w[Illinois IL],
      %w[Indiana IN],
      %w[Iowa IA],
      %w[Kansas KS],
      %w[Kentucky KY],
      %w[Louisiana LA],
      %w[Maine ME],
      %w[Maryland MD],
      %w[Massachusetts MA],
      %w[Michigan MI],
      %w[Minnesota MN],
      %w[Mississippi MS],
      %w[Missouri MO],
      %w[Montana MT],
      %w[Nebraska NE],
      %w[Nevada NV],
      ['New Hampshire', 'NH'],
      ['New Jersey', 'NJ'],
      ['New Mexico', 'NM'],
      ['New York', 'NY'],
      ['North Carolina', 'NC'],
      ['North Dakota', 'ND'],
      %w[Ohio OH],
      %w[Oklahoma OK],
      %w[Oregon OR],
      %w[Pennsylvania PA],
      ['Rhode Island', 'RI'],
      ['South Carolina', 'SC'],
      ['South Dakota', 'SD'],
      %w[Tennessee TN],
      %w[Texas TX],
      %w[Utah UT],
      %w[Vermont VT],
      %w[Virginia VA],
      %w[Washington WA],
      ['West Virginia', 'WV'],
      %w[Wisconsin WI],
      %w[Wyoming WY]
    ]
  end

  # darken a hex color
  # darken_color( hex_color: String, amount: Float )
  # amount should be Float between 0..1
  # lower is darker
  def darken_color(hex_color, amount = 0.2)
    hex_color = hex_color.delete('#')
    rgb       = hex_color.scan(%r{..}).map(&:hex)

    rgb[0] = (rgb[0].to_i * amount).round
    rgb[1] = (rgb[1].to_i * amount).round
    rgb[2] = (rgb[2].to_i * amount).round

    # rubocop:disable Style/FormatString
    '#%02x%02x%02x' % rgb
    # rubocop:enable Style/FormatString
  end

  # lighten a hex color
  # amount should be Float between 0..1
  # higher is lighter
  # lighten_color( hex_color: String, amount: Float )
  def lighten_color(hex_color, amount = 0.8)
    hex_color = hex_color.delete('#')
    rgb       = hex_color.scan(%r{..}).map(&:hex)

    rgb[0] = [(rgb[0].to_i + (amount * 255)).round, 255].min
    rgb[1] = [(rgb[1].to_i + (amount * 255)).round, 255].min
    rgb[2] = [(rgb[2].to_i + (amount * 255)).round, 255].min

    # rubocop:disable Style/FormatString
    '#%02x%02x%02x' % rgb
    # rubocop:enable Style/FormatString
  end

  def contrasting_text_color(hex_color)
    color = hex_color.delete('#')
    convert_to_brightness_value(color) > 382.5 ? darken_color(color) : lighten_color(color)
  end

  def convert_to_brightness_value(hex_color)
    hex_color.scan(%r{..}).sum(&:hex)
  end
end

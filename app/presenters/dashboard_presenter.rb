# frozen_string_literal: true

# app/presenters/dashboard_presenter.rb
class DashboardPresenter < BasePresenter
  attr_reader :tasks_column_header, :tasks_filter_selected

  def initialize(args = {})
    super
    @new_dashboard          = args.dig(:new_dashboard).to_bool

    @dashboard_menu_options = nil
    @date_range             = nil
    @user_settings_buttons  = nil

    @tasks_column_header = {
      'past'    => 'Tasks Past Due',
      'current' => 'Today\'s Tasks',
      'future'  => 'Upcoming Tasks'
    }
    @tasks_filter_selected = {
      'past'    => 'past_due',
      'current' => 'today',
      'future'  => 'up_coming'
    }
  end

  def button_options
    general_options = ['General Buttons', []]
    general_options[1]  << ['Paying Clients', 'paying_clients'] if @user.super_admin?
    general_options[1]  << ['Client Value', 'client_value'] if @user.super_admin?
    general_options[1]  << [' New Contacts', 'user_new_contacts', { data: { icon: 'fa fa-user' } }]
    general_options[1]  << [' Company New Contacts', 'client_new_contacts', { data: { icon: 'fa fa-building' } }] if @user.access_controller?('dashboard', 'company_tiles')

    kpi_options = ['KPI Buttons', []]
    kpi_options[1] << ['Client Text message response time - Average', 'client_text_message_response_time_avg', { data: { icon: 'fa fa-stopwatch' } }]
    kpi_options[1] << ['Client Text message response time - Maximum', 'client_text_message_response_time_max', { data: { icon: 'fa fa-stopwatch' } }]
    kpi_options[1] << ['Client Text message response time - Minimum', 'client_text_message_response_time_min', { data: { icon: 'fa fa-stopwatch' } }]
    kpi_options[1] << ['User Text message response time - Average', 'user_text_message_response_time_avg', { data: { icon: 'fa fa-stopwatch' } }]
    kpi_options[1] << ['User Text message response time - Maximum', 'user_text_message_response_time_max', { data: { icon: 'fa fa-stopwatch' } }]
    kpi_options[1] << ['User Text message response time - Minimum', 'user_text_message_response_time_min', { data: { icon: 'fa fa-stopwatch' } }]

    custom_kpi_options = ['Custom KPI Buttons', []]
    custom_kpi_options[1] += @user.client.client_kpis.order(:name).map { |kpi| [kpi.name, "custom_kpi_#{kpi.id}", { data: { icon: 'fa fa-chart-line' } }] }

    text_options = ['Text Buttons', []]
    text_options[1]     << ['Texts Sent', 'user_texts_sent', { data: { icon: 'fa fa-user' } }]
    text_options[1]     << ['Company Texts Sent', 'client_texts_sent', { data: { icon: 'fa fa-building' } }] if @user.access_controller?('dashboard', 'company_tiles')
    text_options[1]     << ['Texts Received', 'user_texts_received', { data: { icon: 'fa fa-user' } }]
    text_options[1]     << ['Company Texts Received', 'client_texts_received', { data: { icon: 'fa fa-building' } }] if @user.access_controller?('dashboard', 'company_tiles')

    email_options = ['Email Buttons', []]
    email_options[1]     << ['Emails Sent', 'user_emails_sent', { data: { icon: 'fa fa-user' } }]
    email_options[1]     << ['Company Emails Sent', 'client_emails_sent', { data: { icon: 'fa fa-building' } }] if @user.access_controller?('dashboard', 'company_tiles')
    email_options[1]     << ['Emails Received', 'user_emails_received', { data: { icon: 'fa fa-user' } }]
    email_options[1]     << ['Company Emails Received', 'client_emails_received', { data: { icon: 'fa fa-building' } }] if @user.access_controller?('dashboard', 'company_tiles')

    voice_options = ['Call Buttons', []]
    voice_options[1]     << ['Calls Placed', 'user_voice_sent', { data: { icon: 'fa fa-user' } }]
    voice_options[1]     << ['Company Calls Placed', 'client_voice_sent', { data: { icon: 'fa fa-building' } }] if @user.access_controller?('dashboard', 'company_tiles')
    voice_options[1]     << ['Calls Received', 'user_voice_received', { data: { icon: 'fa fa-user' } }]
    voice_options[1]     << ['Company Calls Received', 'client_voice_received', { data: { icon: 'fa fa-building' } }] if @user.access_controller?('dashboard', 'company_tiles')

    if @user.client.campaigns_count.positive?
      campaign_options = ['Campaign Buttons', []]
      campaign_options[1] << ['Completed Campaigns', 'user_campaigns_completed', { data: { icon: 'fa fa-user' } }]
      campaign_options[1] << ['Company Completed Campaigns', 'client_campaigns_completed', { data: { icon: 'fa fa-building' } }] if @user.access_controller?('dashboard', 'company_tiles')
      campaign_options[1] += @user.client.campaigns.order(:name).map { |campaign| ["#{campaign.name} Completed", "user_campaign_#{campaign.id}", { data: { icon: 'fa fa-user' } }] }
      campaign_options[1] += @user.client.campaigns.order(:name).map { |campaign| ["Company #{campaign.name} Completed", "client_campaign_#{campaign.id}", { data: { icon: 'fa fa-building' } }] } if @user.access_controller?('dashboard', 'company_tiles')
      campaign_options[1] += Campaign.keywords(@user.client_id).map { |campaign| ["#{campaign.name} Received", "user_keyword_#{campaign.id}", { data: { icon: 'fa fa-user' } }] }
      campaign_options[1] += Campaign.keywords(@user.client_id).map { |campaign| ["Company #{campaign.name} Received", "client_keyword_#{campaign.id}", { data: { icon: 'fa fa-building' } }] } if @user.access_controller?('dashboard', 'company_tiles')
    else
      campaign_options     = []
    end

    if @user.client.groups_count.positive?
      group_options        = ['Group Buttons', []]
      group_options[1]    += @user.client.groups.order(:name).map { |group| [group.name.to_s, "user_group_#{group.id}", { data: { icon: 'fa fa-user' } }] }
      group_options[1]    += @user.client.groups.order(:name).map { |group| ["Company #{group.name}", "client_group_#{group.id}", { data: { icon: 'fa fa-building' } }] } if @user.access_controller?('dashboard', 'company_tiles')
    else
      group_options        = []
    end

    tag_options          = ['Tag Buttons', []]
    tag_options[1]      += @user.client.tags.order(:name).map { |tag| [tag.name.to_s, "user_tag_#{tag.id}", { data: { icon: 'fa fa-user' } }] }
    tag_options[1]      += @user.client.tags.order(:name).map { |tag| ["Company #{tag.name}", "client_tag_#{tag.id}", { data: { icon: 'fa fa-building' } }] } if @user.access_controller?('dashboard', 'company_tiles')

    if @user.client.trackable_links_count.positive?
      link_options         = ['Trackable Link Buttons', []]
      link_options[1]     += @user.client.trackable_links.order(:name).map { |trackable_link| [trackable_link.name.to_s, "user_trackable_link_#{trackable_link.id}", { data: { icon: 'fa fa-user' } }] }
      link_options[1]     += @user.client.trackable_links.order(:name).map { |trackable_link| ["Company #{trackable_link.name}", "client_trackable_link_#{trackable_link.id}", { data: { icon: 'fa fa-building' } }] } if @user.access_controller?('dashboard', 'company_tiles')
    else
      link_options         = []
    end

    if @user.client.max_voice_recordings.positive?
      rvm_options          = ['Voice Recording Buttons', []]
      rvm_options[1]      += @user.client.voice_recordings.order(:recording_name).map { |voice_recording| [voice_recording.recording_name.to_s, "user_rvm_#{voice_recording.id}", { data: { icon: 'fa fa-user' } }] }
      rvm_options[1]      += @user.client.voice_recordings.order(:recording_name).map { |voice_recording| ["Company #{voice_recording.recording_name}", "client_rvm_#{voice_recording.id}", { data: { icon: 'fa fa-building' } }] } if @user.access_controller?('dashboard', 'company_tiles')
    else
      rvm_options          = []
    end

    [general_options, kpi_options, custom_kpi_options, text_options, email_options, voice_options] + (campaign_options.empty? ? [] : [campaign_options]) + (group_options.empty? ? [] : [group_options]) + [tag_options] + (link_options.empty? ? [] : [link_options]) + (rvm_options.empty? ? [] : [rvm_options])
  end

  def config_form_method
    self.user_settings_buttons.new_record? ? :post : :patch
  end

  def config_form_url
    self.user_settings_buttons.new_record? ? Rails.application.routes.url_helpers.dashboards_path : Rails.application.routes.url_helpers.dashboard_path(self.dashboard_id)
  end

  def current_time
    Time.use_zone(self.client.time_zone) { Chronic.parse(Time.current.to_s) }.to_i
  end

  def custom_kpi_criteria(criteria, in_period)
    if criteria.present?
      criteria_split = criteria.split('_')
      criteria_id    = criteria_split.last.to_i
      criteria_split.pop if criteria_id.positive?
      criteria_type  = criteria_split.join('_')
      criteria_range = in_period ? [self.date_range[0], self.date_range[1]] : [Time.parse('2018-01-01 00:00:00 UTC'), Time.current]

      response = if criteria_type[0, 5] == 'user_'
                   case criteria_type[5, criteria_type.length]
                   when 'campaign', 'keyword'
                     Contacts::Campaign.campaign_completed_by_user(criteria_id, self.user_settings_buttons.data[:buttons_user_id], criteria_range[0], criteria_range[1]).count
                   when 'campaigns_completed'
                     Contacts::Campaign.campaigns_completed_by_user(self.user_settings_buttons.data[:buttons_user_id], criteria_range[0], criteria_range[1]).count
                   when 'emails_received'
                     Messages::Message.emails_received_by_user(self.user_settings_buttons.data[:buttons_user_id], criteria_range[0], criteria_range[1]).count
                   when 'group'
                     Contact.group_by_user(self.user_settings_buttons.data[:buttons_user_id], criteria_id, criteria_range[0], criteria_range[1]).count
                   when 'new_contacts'
                     self.client.contacts.where(created_at: criteria_range[0]..criteria_range[1]).where(user_id: self.user_settings_buttons.data[:buttons_user_id]).count
                   when 'rvm'
                     Messages::Message.voice_recordings_delivered_by_user(criteria_id, self.user_settings_buttons.data[:buttons_user_id], criteria_range[0], criteria_range[1]).count
                   when 'tag'
                     Contacttag.by_tag_and_user_and_period(criteria_id, self.user_settings_buttons.data[:buttons_user_id], criteria_range[0], criteria_range[1]).count
                   when 'texts_received'
                     Messages::Message.texts_received_by_user(self.user_settings_buttons.data[:buttons_user_id], criteria_range[0], criteria_range[1]).count
                   when 'texts_sent'
                     Messages::Message.texts_sent_by_user(self.user_settings_buttons.data[:buttons_user_id], criteria_range[0], criteria_range[1]).count
                   when 'trackable_link'
                     TrackableLink.contacts_delivered_by_user(criteria_id, self.user_settings_buttons.data[:buttons_user_id], criteria_range[0], criteria_range[1]).uniq.count
                   when 'voice_received'
                     Messages::Message.voice_received_by_user(self.user_settings_buttons.data[:buttons_user_id], criteria_range[0], criteria_range[1]).count
                   when 'voice_sent'
                     Messages::Message.voice_sent_by_user(self.user_settings_buttons.data[:buttons_user_id], criteria_range[0], criteria_range[1]).count
                   else
                     0
                   end
                 elsif criteria_type[0, 7] == 'client_' && self.user.access_controller?('dashboard', 'company_tiles')
                   case criteria_type[7, criteria_type.length]
                   when 'campaign', 'keyword'
                     Contacts::Campaign.campaign_completed(criteria_id, criteria_range[0], criteria_range[1]).count
                   when 'campaigns_completed'
                     Contacts::Campaign.campaigns_completed(self.client.id, criteria_range[0], criteria_range[1]).count
                   when 'emails_received'
                     Messages::Message.emails_received_by_client(self.client.id, criteria_range[0], criteria_range[1]).count
                   when 'group'
                     Contact.group_by_client(self.client.id, criteria_id, criteria_range[0], criteria_range[1]).count
                   when 'new_contacts'
                     self.client.contacts.where(created_at: criteria_range[0]..criteria_range[1]).count
                   when 'rvm'
                     Messages::Message.voice_recordings_delivered(criteria_id, criteria_range[0], criteria_range[1]).count
                   when 'tag'
                     Contacttag.by_tag_and_period(criteria_id, criteria_range[0], criteria_range[1]).count
                   when 'texts_received'
                     Messages::Message.texts_received_by_client(self.client.id, criteria_range[0], criteria_range[1]).count
                   when 'texts_sent'
                     Messages::Message.texts_sent_by_client(self.client.id, criteria_range[0], criteria_range[1]).count
                   when 'trackable_link'
                     TrackableLink.contacts_delivered(criteria_id, criteria_range[0], criteria_range[1]).uniq.count
                   when 'voice_received'
                     Messages::Message.voice_received_by_client(self.client.id, criteria_range[0], criteria_range[1]).count
                   when 'voice_sent'
                     Messages::Message.voice_sent_by_client(self.client.id, criteria_range[0], criteria_range[1]).count
                   else
                     0
                   end
                 else
                   0
                 end
    else
      response = 0
    end

    response
  end

  def dashboard_buttons
    self.user_settings_buttons.data.dig(:dashboard_buttons) || []
  end

  def dashboard_buttons_user_id
    self.user_settings_buttons.data[:buttons_user_id]
  end

  def dashboard_id
    self.user_settings_buttons.id
  end

  def dashboard_menu_options
    @dashboard_menu_options ||= self.user.user_settings.where(controller_action: 'dashboard_buttons').collect { |user_setting| [user_setting.name, user_setting.id] }.sort
  end

  def dashboard_name
    self.user_settings_buttons.name
  end

  def dashboard_name_valid
    self.user_settings_buttons.name.present? ? 'is-valid' : 'is-invalid'
  end

  def date_range
    @date_range ||= Users::Dashboards::Dashboard.new.date_range_calc(
      time_zone: self.client.time_zone,
      dynamic:   self.user_settings_buttons.data[:dynamic],
      from:      self.user_settings_buttons.data[:from],
      to:        self.user_settings_buttons.data[:to]
    )
  end

  def description
    if self.date_range
      self.user_settings_buttons.data[:dynamic].present? ? Users::Dashboards::Dashboard::DYNAMIC_DATES_ARRAY.to_h.invert[self.user_settings_buttons.data[:dynamic]] : "Custom Period: #{Friendly.new.date(self.date_range[0], self.client.time_zone, true)} to #{Friendly.new.date(self.date_range[1], self.client.time_zone, true)}"
    else
      'Custom Period: Undefined'
    end
  end

  def google_calendar_events
    response = []

    if (user_api_integration = self.user.user_api_integrations.find_by(target: 'google', name: '')) && Integration::Google.valid_token?(user_api_integration)
      ggl_client = Integrations::Ggl::Calendar.new(user_api_integration.token, I18n.t('tenant.id'))

      user_api_integration.dashboard_calendars.map(&:symbolize_keys).each do |calendar|
        ggl_client.event_list_for_calendar(calendar_id: calendar.dig(:id), start_date: DateTime.current.beginning_of_month, end_date: DateTime.current.end_of_month + 12.months, time_zone: self.client.time_zone)

        response << "{events: #{ggl_client.result.to_json}, color: '#{calendar[:background_color]}', textColor: '#{calendar[:foreground_color]}'}" if ggl_client.success?
      end
    end

    response.join(', ')
  end

  def greeting
    if self.midnight.upto(self.noon).include?(self.current_time)
      'Good Morning'
    elsif self.noon.upto(self.six_pm).include?(self.current_time)
      'Good Afternoon'
    elsif self.six_pm.upto(self.midnight + 1.day).include?(self.current_time)
      'Good Evening'
    end
  end

  def midnight
    Time.use_zone(self.client.time_zone) { Chronic.parse(Time.current.to_s) }.beginning_of_day.to_i
  end

  def noon
    Time.use_zone(self.client.time_zone) { Chronic.parse(Time.current.to_s) }.middle_of_day.to_i
  end

  def period_custom_string
    !self.user_settings_buttons.data[:from].empty? && !self.user_settings_buttons.data[:to].empty? ? "#{self.user_settings_buttons.data[:from]} to #{self.user_settings_buttons.data[:to]}" : "#{self.user_settings_buttons.data[:from]}#{self.user_settings_buttons.data[:to]}"
  end

  def period_dropdown_string
    self.user_settings_buttons.data[:dynamic].empty? ? 'Custom Period' : Users::Dashboards::Dashboard::DYNAMIC_DATES_ARRAY.to_h.invert[self.user_settings_buttons.data[:dynamic]]
  end

  def period_dynamic
    self.user_settings_buttons.data[:dynamic].to_s
  end

  def period_greeting_string
    self.period_dropdown_string.casecmp?('custom period') ? self.period_custom_string.to_s : self.period_dropdown_string.downcase
  end

  def six_pm
    Time.use_zone(self.client.time_zone) { Chronic.parse(Time.current.to_s) }.change(hour: 18).to_i
  end

  def tasks_collection(column_type)
    case column_type
    when 'past'
      self.client.tasks.past_due.where(self.user_for_tasks.zero? ? '1=1' : "user_id=#{self.user_for_tasks}").order(:due_at).limit(5)
    when 'current'
      self.client.tasks.current.where(self.user_for_tasks.zero? ? '1=1' : "user_id=#{self.user_for_tasks}").order(:due_at).limit(5)
    when 'future'
      self.client.tasks.future.where(self.user_for_tasks.zero? ? '1=1' : "user_id=#{self.user_for_tasks}").order(:due_at).limit(5)
    end
  end

  def text_response_time(client_or_user, type)
    if client_or_user == :client
      case type.to_sym
      when :avg
        Users::Dashboards::Message.new.average_text_response_time(self.date_range.first, self.date_range.last, self.user.client, nil)
      when :max
        Users::Dashboards::Message.new.maximum_text_response_time(self.date_range.first, self.date_range.last, self.user.client, nil)
      when :min
        Users::Dashboards::Message.new.minimum_text_response_time(self.date_range.first, self.date_range.last, self.user.client, nil)
      end
    else
      case type.to_sym
      when :avg
        Users::Dashboards::Message.new.average_text_response_time(self.date_range.first, self.date_range.last, self.user.client, self.user)
      when :max
        Users::Dashboards::Message.new.maximum_text_response_time(self.date_range.first, self.date_range.last, self.user.client, self.user)
      when :min
        Users::Dashboards::Message.new.minimum_text_response_time(self.date_range.first, self.date_range.last, self.user.client, self.user)
      end
    end
  end

  def texts_responded_by_user
    texts_in = Messages::Message.texts_received_by_user(self.user, self.date_range.first, self.date_range.last).select('contact_id, MAX(messages.created_at) AS created_at').group(:contact_id)
    texts_out = self.user.messages.where(msg_type: Messages::Message::MSG_TYPES_TEXTOUT).where(created_at: self.date_range.first..self.date_range.last).where(contact_id: texts_in.map(&:contact_id)).select('contact_id, MAX(messages.created_at) AS created_at').group(:contact_id)

    responded = texts_out.to_a.delete_if { |text_out| text_out.created_at < texts_in.find { |text_in| text_in.contact_id == text_out.contact_id }.created_at }

    [responded.length, texts_in.length]
  end

  def texts_responded_by_client
    texts_in = Messages::Message.texts_received_by_client(self.user.client, self.date_range.first, self.date_range.last).select('contact_id, MAX(messages.created_at) AS created_at').group(:contact_id)
    texts_out = self.user.client.messages.where(msg_type: Messages::Message::MSG_TYPES_TEXTOUT).where(created_at: self.date_range.first..self.date_range.last).where(contact_id: texts_in.map(&:contact_id)).select('contact_id, MAX(messages.created_at) AS created_at').group(:contact_id)

    responded = texts_out.to_a.delete_if { |text_out| text_out.created_at < texts_in.find { |text_in| text_in.contact_id == text_out.contact_id }.created_at }

    [responded.length, texts_in.length]
  end

  def user_for_tasks
    self.user.access_controller?('dashboard', 'all_contacts') ? (self.user_settings_buttons.data.dig(:user_for_tasks) || 0).to_i : self.user.id
  end

  def user_settings_buttons
    @user_settings_buttons ||= if @new_dashboard
                                 self.user.user_settings.new(controller_action: 'dashboard_buttons', current: 1)
                               else
                                 self.user.user_settings.find_or_initialize_by(controller_action: 'dashboard_buttons', current: 1)
                               end
  end

  def users_with_tasks_for_select
    [['All Users', 0]] + self.client.users.with_tasks.pluck(:firstname, :lastname, :id).map { |user| [Friendly.new.fullname(user[0], user[1]), user[2]] }
  end
end

# frozen_string_literal: true

# app/presenters/client_presenter.rb
class ClientPresenter
  attr_accessor :custom_field, :folder, :group, :tag, :transaction_type
  attr_reader :client, :statement_month

  def initialize(args = {})
    self.client = args.dig(:client)

    @custom_field     = nil
    @folder           = nil
    @group            = nil
    @tag              = nil
    @transaction_type = ''
  end

  def assigned_campaign
    self.client.task_actions.dig('assigned', 'campaign_id').positive? ? self.client.campaigns.find_by(id: @client.task_actions['assigned']['campaign_id']) : self.client.campaigns.new
  end

  def assigned_group
    self.client.task_actions.dig('assigned', 'group_id').positive? ? self.client.groups.find_by(id: @client.task_actions['assigned']['group_id']) : self.client.groups.new
  end

  def assigned_tag
    self.client.task_actions.dig('assigned', 'tag_id').positive? ? self.client.tags.find_by(id: @client.task_actions['assigned']['tag_id']) : self.client.tags.new
  end

  def assigned_stage
    self.client.task_actions.dig('assigned', 'stage_id')&.to_i&.positive? ? self.client.stages.find_by(id: @client.task_actions['assigned']['stage_id']) : self.client.stages.new
  end

  def assigned_stop_campaigns
    return ['All Campaigns'] if self.assigned_stop_campaign_ids&.include?(0)

    Campaign.where(client_id: self.client.id, id: self.assigned_stop_campaign_ids).pluck(:name)
  end

  def assigned_stop_campaign_ids
    self.client.task_actions.dig('assigned', 'stop_campaign_ids').nil? ? [] : self.client.task_actions.dig('assigned', 'stop_campaign_ids').compact_blank
  end

  def associated_contact_link
    self.client.contact_id.positive? && self.client.contact ? ActionController::Base.helpers.link_to(self.client.contact.fullname, Rails.application.routes.url_helpers.central_path(contact_id: self.client.contact_id), { class: 'btn btn-info' }) : 'No Associated Contact'
  end

  def billing_info
    self.monthly_payment_past_due ? "(past due / #{I18n.t(:attempt, count: self.client.mo_charge_retry_count.to_i)})" : ''
  end

  def client=(client)
    @client = case client
              when Client
                client
              when Integer
                Client.find_by(id: client)
              else
                Client.new
              end

    @client_transaction_totals = nil
    @group_contacts_count      = nil
    @package                   = nil
    @package_page              = nil
    @statement_month           = nil
    @tags                      = nil
  end

  def client_avatar
    if self.client.logo_image.present?
      ActionController::Base.helpers.image_tag(Cloudinary::Utils.cloudinary_url(self.client.logo_image.key, { secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), format: 'png' }))
    else
      ActionController::Base.helpers.image_tag("tenant/#{I18n.t('tenant.id')}/logo-600.png")
    end
  end

  def client_found_in_vitally
    Integration::Vitally::V2024::Base.new.client_found?(self.client.id)
  end

  def client_name
    self.client.name
  end

  def client_next_pmt_date_formatted
    self.client.next_pmt_date.present? ? self.client.next_pmt_date.in_time_zone(self.client.time_zone).strftime('%m/%d/%Y') : ''
  end

  def client_onboarding_scheduled_formatted
    self.client.onboarding_scheduled.present? ? Time.use_zone(self.client.time_zone) { Chronic.parse(self.client.onboarding_scheduled) }.strftime('%m/%d/%Y %I:%M %p') : ''
  end

  def client_phone_formatted
    ActionController::Base.helpers.number_to_phone(self.client.phone)
  end

  def client_terms_accepted_formatted
    self.client.terms_accepted.present? ? Time.use_zone(self.client.time_zone) { Chronic.parse(self.client.terms_accepted) }.strftime('%m/%d/%Y %I:%M %p') : ''
  end

  def client_transaction_totals
    start_date = self.client_transactions_start_date
    @client_transaction_totals ||= self.client.client_transactions.select(:setting_key, :setting_value).where(created_at: [start_date..start_date.end_of_month]).group(:setting_key).sum('setting_value::decimal')
  end

  def client_transactions
    start_date = self.client_transactions_start_date
    self.client.client_transactions.where(created_at: [start_date..start_date.end_of_month], setting_key: (@transaction_type == 'dlc10_charges' ? %w[dlc10_brand_charge dlc10_campaign_charge dlc10_campaign_mo_charge] : @transaction_type)).order(:created_at)
  end

  def client_transactions_start_date
    self.statement_month.present? ? self.current_client_time.beginning_of_month.change(month: self.statement_month.split(':')[0]).change(year: self.statement_month.split(':')[1]) : self.current_client_time.beginning_of_month
  end

  def completed_campaign
    self.client.task_actions.dig('completed', 'campaign_id').positive? ? self.client.campaigns.find_by(id: self.client.task_actions['completed']['campaign_id']) : @client.campaigns.new
  end

  def completed_group
    self.client.task_actions.dig('completed', 'group_id').positive? ? self.client.groups.find_by(id: self.client.task_actions['completed']['group_id']) : @client.groups.new
  end

  def completed_tag
    self.client.task_actions.dig('completed', 'tag_id').positive? ? self.client.tags.find_by(id: self.client.task_actions['completed']['tag_id']) : @client.tags.new
  end

  def completed_stage
    self.client.task_actions.dig('completed', 'stage_id')&.to_i&.positive? ? self.client.stages.find_by(id: @client.task_actions['completed']['stage_id']) : self.client.stages.new
  end

  def completed_stop_campaigns
    return ['All Campaigns'] if self.completed_stop_campaign_ids&.include?(0)

    Campaign.where(client_id: self.client.id, id: self.completed_stop_campaign_ids).pluck(:name)
  end

  def completed_stop_campaign_ids
    self.client.task_actions.dig('completed', 'stop_campaign_ids').nil? ? [] : self.client.task_actions.dig('completed', 'stop_campaign_ids').compact_blank
  end

  def credit_balance
    self.client_transaction_totals.dig('credits_added').to_d - self.client_transaction_totals.dig('text_message_credits').to_d - self.client_transaction_totals.dig('text_image_credits').to_d - self.client_transaction_totals.dig('phone_call_credits').to_d - self.client_transaction_totals.dig('rvm_credits').to_d - self.client_transaction_totals.dig('video_call_credits').to_d
  end

  def credit_card_string
    "#{self.client.card_brand} | #{self.client.card_last4} | #{self.client.card_exp_month}/#{self.client.card_exp_year}"
  end

  def current_balance
    self.client.current_balance.to_d / 100
  end

  def current_client_time
    DateTime.current.in_time_zone(self.client.time_zone)
  end

  def custom_field_type_options
    [
      %w[Text string],
      %w[Number numeric],
      %w[Currency currency],
      %w[Stars stars],
      %w[Date date]
    ]
  end

  def custom_fields
    self.client.client_custom_fields.order(:var_name)
  end

  def date_created_string
    Friendly.new.date(self.client.created_at, self.client.time_zone, true)
  end

  def deadline_campaign
    self.client.task_actions.dig('deadline', 'campaign_id').positive? ? self.client.campaigns.find_by(id: self.client.task_actions['deadline']['campaign_id']) : @client.campaigns.new
  end

  def deadline_group
    self.client.task_actions.dig('deadline', 'group_id').positive? ? self.client.groups.find_by(id: self.client.task_actions['deadline']['group_id']) : @client.groups.new
  end

  def deadline_tag
    self.client.task_actions.dig('deadline', 'tag_id').positive? ? self.client.tags.find_by(id: self.client.task_actions['deadline']['tag_id']) : @client.tags.new
  end

  def deadline_stage
    self.client.task_actions.dig('deadline', 'stage_id')&.to_i&.positive? ? self.client.stages.find_by(id: @client.task_actions['deadline']['stage_id']) : self.client.stages.new
  end

  def deadline_stop_campaigns
    return ['All Campaigns'] if self.deadline_stop_campaign_ids&.include?(0)

    Campaign.where(client_id: self.client.id, id: self.deadline_stop_campaign_ids).pluck(:name)
  end

  def deadline_stop_campaign_ids
    self.client.task_actions.dig('deadline', 'stop_campaign_ids').nil? ? [] : self.client.task_actions.dig('deadline', 'stop_campaign_ids').compact_blank
  end

  def default_credits_to_add
    self.client.current_credit_charge.to_d.positive? ? (20 / self.client.current_credit_charge.to_d).to_i : 0
  end

  def dlc10_charges
    self.client_transaction_totals.dig('dlc10_brand_charge').to_d + self.client_transaction_totals.dig('dlc10_campaign_charge').to_d + self.client_transaction_totals.dig('dlc10_campaign_mo_charge').to_d
  end

  def due_campaign
    self.client.task_actions.dig('due', 'campaign_id').positive? ? self.client.campaigns.find_by(id: @client.task_actions['due']['campaign_id']) : @client.campaigns.new
  end

  def due_group
    self.client.task_actions.dig('due', 'group_id').positive? ? self.client.groups.find_by(id: @client.task_actions['due']['group_id']) : @client.groups.new
  end

  def due_tag
    self.client.task_actions.dig('due', 'tag_id').positive? ? self.client.tags.find_by(id: @client.task_actions['due']['tag_id']) : self.client.tags.new
  end

  def due_stage
    self.client.task_actions.dig('due', 'stage_id')&.to_i&.positive? ? self.client.stages.find_by(id: @client.task_actions['due']['stage_id']) : self.client.stages.new
  end

  def due_stop_campaigns
    return ['All Campaigns'] if self.due_stop_campaign_ids&.include?(0)

    Campaign.where(client_id: self.client.id, id: self.due_stop_campaign_ids).pluck(:name)
  end

  def due_stop_campaign_ids
    self.client.task_actions.dig('due', 'stop_campaign_ids').nil? ? [] : self.client.task_actions.dig('due', 'stop_campaign_ids').compact_blank
  end

  def folders
    self.client.folders.order(:name)
  end

  def group_contacts_count(group_id)
    (@group_contacts_count ||= self.client.groups.select('groups.id AS id, COUNT(contacts.id) AS contact_count').joins(:contacts).group('id'))&.find { |g| g.id == group_id }&.contact_count
  end

  def groups
    self.client.groups.order(:name)
  end

  def monthly_payment_past_due
    self.client.next_pmt_date < Time.current
  end

  def minimum_credit_purchase
    self.client.current_credit_charge.to_d.positive? ? (5 / self.client.current_credit_charge.to_d).to_i : 0
  end

  def next_payment_date_string
    self.client.next_pmt_date ? self.client.next_pmt_date.strftime('%m/%d/%Y') : ''
  end

  def ok_to_enter_max_phone_numbers
    self.client.current_max_phone_numbers.positive?
  end

  def ok_to_select_default_user
    (self.client.max_contacts_count == -1 || self.client.max_contacts_count.positive?) && !self.client.new_record?
  end

  def onboarding_scheduled_string
    self.client.onboarding_scheduled.present? ? self.client.onboarding_scheduled.in_time_zone(self.client.time_zone).strftime('%m/%d/%Y %I:%M %p') : ''
  end

  def options_for_package
    packages = []

    if self.package_page
      package  = self.package_page.package_01
      packages << [package.name, package.id] if package
      package  = self.package_page.package_02
      packages << [package.name, package.id] if package
      package  = self.package_page.package_03
      packages << [package.name, package.id] if package
      package  = self.package_page.package_04
      packages << [package.name, package.id] if package
    end

    packages
  end

  def options_for_statement_month
    date = self.client.created_at.beginning_of_month
    select_array = []

    while date <= Time.current
      select_array << ["#{Date::MONTHNAMES[date.month]}, #{date.year}", "#{date.month}:#{date.year}"]
      date += 1.month
    end

    select_array
  end

  def package
    @package ||= self.client.package
  end

  def package_name
    self.package ? self.package.name : 'Unknown'
  end

  def package_page
    @package_page ||= self.client.package_page
  end

  def package_page_name
    self.package_page ? self.package_page.name : 'Unknown'
  end

  def package_upgradable?
    self.client.package_upgradable? && self.client.credit_card_on_file?
  end

  def radio_buttons_active_status
    buttons = []
    buttons << { label: 'Active', value: 'true', id: 'radio_active_status' }
    buttons << { label: 'In-Active', value: 'false', id: 'radio_inactive_status' }
  end

  def radio_buttons_text_message_pricing_method
    buttons = []
    buttons << { label: 'Fixed Rate', value: 0, id: 'client_fixed_rate' }
    buttons << { label: 'Graduated Rate', value: 1, id: 'client_graduated_rate' }
    buttons << { label: 'Flat Fee', value: 2, id: 'client_flat_fee' }
  end

  def row_columns(current_user, _session)
    current_user.team_member? ? [6, 6] : [3, 9]
  end

  def show_partial(client_page_section)
    case client_page_section
    when 'custom_fields', 'folders', 'groups', 'holidays', 'kpis', 'lead_sources', 'org_chart', 'phone_numbers', 'stage_parents', 'tags', 'users', 'voice_recordings'
      'index'
    when 'statements'
      'show'
    when 'dlc10'
      'v2/edit'
    else
      'edit'
    end
  end

  # (opt) statement_month: (String) "Month (Integer):Year (Integer)" ex: "9:2023"
  def statement_month=(statement_month)
    statement_month = "#{DateTime.current.in_time_zone(self.client.time_zone).month}:#{DateTime.current.in_time_zone(self.client.time_zone).year}" if statement_month.blank?
    @client_transaction_totals = nil unless self.statement_month == statement_month.to_s
    @statement_month = statement_month.to_s
  end

  def tag_color
    @tag.color.empty? ? '#2196f3' : @tag.color
  end

  def tags
    self.client.tags.select('tags.*, count(contacts.id) AS contact_count').left_outer_joins(:contacts).group(:id).includes(:campaign).order('LOWER(name)')
  end

  def terms_accepted_string
    self.client.terms_accepted.present? ? self.client.terms_accepted.in_time_zone(self.client.time_zone).strftime('%m/%d/%Y %I:%M %p') : ''
  end

  def total_charges
    self.client_transaction_totals.dig('startup_costs').to_d + self.client_transaction_totals.dig('mo_charge').to_d + self.client_transaction_totals.dig('credit_charge').to_d + self.client_transaction_totals.dig('added_charge').to_d + self.dlc10_charges.to_d
  end

  def user_avatar(user)
    if user.avatar.present?
      ActionController::Base.helpers.image_tag(Cloudinary::Utils.cloudinary_url(user.avatar.key, { secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), format: 'png' }))
    else
      ActionController::Base.helpers.image_tag("tenant/#{I18n.t('tenant.id')}/logo-600.png")
    end
  end

  def users
    self.client.users.order(:lastname, :firstname)
  end
end

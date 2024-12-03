# frozen_string_literal: true

# app/models/client.rb
class Client < ApplicationRecord
  include Integrationable

  class ClientNotSavedError < StandardError; end
  class ClientPaymentDateNotAdvancedError < StandardError; end

  after_initialize  :apply_defaults, if: :new_record?
  before_validation :before_validation_actions
  before_save       :advance_pmt_date, if: proc { |model| !model.new_record? && model.next_pmt_date.blank? }
  around_destroy    :destroy_external_resources

  has_one_attached :logo_image

  belongs_to :contact, optional: true
  belongs_to :def_user, class_name: :User
  belongs_to :affiliate, class_name: 'Affiliates::Affiliate', optional: true
  belongs_to :package, optional: true
  belongs_to :package_page, optional: true

  has_one  :dlc10_brand,               dependent: :destroy, class_name: 'Clients::Dlc10::Brand'

  has_many :aiagents,                  dependent: :destroy
  has_many :api_calls,                 dependent: :destroy, class_name: 'Clients::ApiCall'
  has_many :campaigns,                 dependent: :destroy
  has_many :client_custom_fields,      dependent: :destroy
  has_many :client_transactions,       dependent: :destroy
  has_many :client_widgets,            dependent: :destroy, class_name: 'Clients::Widget'
  has_many :contacts,                  dependent: :destroy
  has_many :campaign_groups,           dependent: :destroy
  has_many :folders,                   dependent: :destroy
  has_many :groups,                    dependent: :destroy
  has_many :holidays,                  dependent: :destroy, class_name: 'Clients::Holiday'
  has_many :client_kpis,               dependent: :delete_all, class_name: 'Clients::Kpi'
  has_many :lead_sources,              dependent: :destroy, class_name: 'Clients::LeadSource'
  has_many :notes,                     dependent: :destroy, class_name: 'Clients::Note'
  has_many :org_positions,             dependent: :destroy
  has_many :org_users,                 dependent: :delete_all
  has_many :payment_transactions,      dependent: :nullify
  has_many :postcards,                 dependent: :delete_all
  has_many :reviews,                   dependent: :delete_all
  has_many :short_codes,               dependent: :destroy
  has_many :stage_parents,             dependent: :destroy
  has_many :surveys,                   dependent: :destroy, class_name: 'Surveys::Survey'
  has_many :tags,                      dependent: :destroy
  has_many :twnumbers,                 dependent: :destroy
  has_many :tasks,                     dependent: :destroy
  has_many :webhooks,                  dependent: :destroy
  has_many :client_attachments,        dependent: :destroy
  has_many :client_api_integrations,   dependent: :destroy
  has_many :email_templates,           dependent: :destroy
  has_many :quick_responses,           dependent: :destroy
  has_many :trackable_links,           dependent: :destroy
  has_many :users,                     dependent: :destroy
  has_many :user_contact_forms,        through: :users
  has_many :messages,                  through: :users, class_name: '::Messages::Message'
  has_many :voice_recordings,          dependent: :destroy

  has_many :stages,                    dependent: :destroy, through: :stage_parents

  # Client Profile
  store_accessor :data, :primary_area_code

  # Client Settings
  store_accessor :data, :active, :agency_access, :dlc10_required, :dlc10_charged,
                 :contact_matching_ignore_emails, :contact_matching_with_email, :credit_charge, :credit_charge_retry_level, :domains, :first_payment_delay_days, :first_payment_delay_months, :fp_affiliate,
                 :max_phone_numbers, :mo_charge, :mo_charge_retry_count, :mo_credits, :my_agencies, :onboarding_scheduled,
                 :promo_credit_charge, :promo_max_phone_numbers, :promo_mo_charge, :promo_mo_credits, :promo_months, :searchlight_fee, :setup_fee,
                 :terms_accepted, :text_delay, :trial_credits, :unlimited

  #  Client Features
  store_accessor :data, :campaigns_count, :custom_fields_count, :folders_count, :groups_count, :max_email_templates, :import_contacts_count, :integrations_allowed,
                 :max_contacts_count, :max_kpis_count, :max_users_count, :max_voice_recordings, :message_central_allowed, :my_contacts_allowed, :my_contacts_group_actions_all_allowed,
                 :phone_call_credits, :phone_calls_allowed, :quick_leads_count, :rvm_allowed, :rvm_credits,
                 :share_email_templates_allowed, :share_funnels_allowed, :share_quick_leads_allowed, :share_surveys_allowed, :share_widgets_allowed, :share_stages_allowed, :stages_count, :surveys_count,
                 :tasks_allowed, :text_image_credits, :text_message_credits, :text_message_images_allowed, :text_segment_charge_type, :trackable_links_count, :training,
                 :user_chat_allowed, :video_call_credits, :video_calls_allowed, :widgets_count

  # AI Agent Features
  store_accessor :data, :aiagent_base_charge, :aiagent_included_count, :aiagent_overage_paid_count, :aiagent_overage_charge, :aiagent_message_credits, :share_aiagents_allowed,
                 :aiagent_trial_started_at, :aiagent_trial_ended_at, :aiagent_trial_paid_at, :aiagent_trial_period_days, :aiagent_trial_period_months, :aiagent_terms_accepted_at

  # Client Billing
  store_accessor :data, :auto_add_amount, :auto_min_amount, :auto_recharge, :card_brand, :card_exp_month, :card_exp_year, :card_last4, :card_token, :client_token

  # Task Actions
  store_accessor :data, :task_actions

  # miscellaneous
  store_accessor :data, :contact_phone_labels, :locked_at

  # ScheduleOnce
  store_accessor :data, :scheduleonce_api_key, :scheduleonce_booking_canceled, :scheduleonce_booking_canceled_reschedule_requested, :scheduleonce_booking_canceled_then_rescheduled, :scheduleonce_booking_completed, :scheduleonce_booking_no_show, :scheduleonce_booking_rescheduled, :scheduleonce_booking_scheduled, :scheduleonce_webhook_id

  validates :name, presence: true, length: { minimum: 5 }
  validates :phone, presence: true, length: { is: 10 }
  validates :state, length: { maximum: 2 }
  validates :tenant, presence: true

  scope :active, -> {
    where('clients.data @> ?', { active: true }.to_json)
  }
  scope :agency_accounts, ->(client_id) {
    where('data @> ?', { my_agencies: [client_id] }.to_json)
  }
  scope :by_agency, ->(client_id) {
    where('clients.data @> ?', { my_agencies: [client_id] }.to_json)
  }
  scope :delinquent, -> {
    where("(clients.data ->> 'mo_charge_retry_count')::int > ?", 3)
  }
  scope :free, -> {
    where("(clients.data ->> 'mo_charge')::float = ? AND (clients.data ->> 'promo_mo_charge')::float = ?", 0.0, 0.0)
  }
  scope :in_danger, -> {
    where("(clients.data ->> 'mo_charge_retry_count')::int > ? OR (clients.data @> ? AND clients.data @> ? AND (clients.data ->> 'auto_min_amount')::int > (clients.current_balance/100)) OR (clients.data @> ? AND clients.data @> ?)",
          3,
          { active: true }.to_json,
          { unlimited: false }.to_json,
          { client_token: '' }.to_json,
          { unlimited: false }.to_json)
  }
  scope :paying, -> {
    where("(clients.data ->> 'mo_charge')::float > ? OR (clients.data ->> 'promo_mo_charge')::float > ?", 0.0, 0.0)
  }
  scope :search_by_name, ->(client_name) {
    where('clients.name ilike ?', "%#{client_name}%")
  }
  scope :with_integration_allowed, ->(integration_allowed) {
    where("clients.data->'integrations_allowed' ?& array[:options]", options: integration_allowed)
  }
  scope :with_messages, -> {
    select('clients.*, COUNT(messages.id) AS messages')
      .where(tenant: I18n.t('tenant.id'))
      .left_outer_joins(:contacts)
      .left_outer_joins(contacts: :messages)
      .group(:id)
  }
  scope :with_phone_numbers, -> {
    select('clients.*, COUNT(twnumbers.id) AS phone_numbers')
      .where(tenant: I18n.t('tenant.id'))
      .left_outer_joins(:twnumbers)
      .group(:id)
  }
  scope :with_users, -> {
    select('clients.*, COUNT(users.id) AS user_count')
      .where(tenant: I18n.t('tenant.id'))
      .joins(:users)
      .group(:id)
  }

  def active?
    self.active.to_bool
  end

  # add credits to a Client account
  # client.add_credits( { credits_amt: Integer } )
  def add_credits(args = {})
    credits_amt = args.dig(:credits_amt).to_d

    return unless credits_amt.positive? && !self.unlimited

    # rubocop:disable Rails/SkipsModelValidations
    Client.where(id: self.id).update_all("current_balance = current_balance + #{(credits_amt * BigDecimal(100)).to_i}")
    # rubocop:enable Rails/SkipsModelValidations
    self.client_transactions.create(setting_key: 'credits_added', setting_value: credits_amt)
    self.reload
  end

  # charge a Client credit card and add the credits to Client account
  # result = client.add_credits_by_charge(credits_amt: Integer)
  # result = client.add_credits_by_charge(credits_amt: Integer, force: true)
  def add_credits_by_charge(args = {})
    credits_amt   = args.dig(:credits_amt).to_i     # number of credits to add to Client's account
    force         = args.dig(:force).to_bool        # add credits even if current balance is above recharge level
    response      = { success: false, transaction_id: '', error_code: '', error_message: '' }

    if credits_amt.positive? &&
       self.credit_card_on_file? &&
       self.current_credit_charge.to_d.positive? &&
       (force || ((self.current_balance / 100).to_i <= self.credit_charge_retry_level.to_i)) &&
       (force || self.credit_charge_retry_level.to_i >= 15)

      charge_amt = (credits_amt * self.current_credit_charge.to_d)

      if self.changed?
        error = ClientNotSavedError.new("Client #{self.name} (#{self.id}) NOT saved!")
        error.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(error) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('Client.add_credits_by_charge')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(args)

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            changes: self.changes,
            file:    __FILE__,
            line:    __LINE__
          )
        end
        self.save
      end

      ok2charge = false

      self.with_lock do
        if self.locked_at.nil? || (self.locked_at < 1.minute.ago)
          self.update(locked_at: Time.current)
          ok2charge = true
        end
      end

      if ok2charge && (force || ((self.current_balance / 100).to_i <= self.credit_charge_retry_level.to_i))
        result = self.charge_card(
          charge_amount: charge_amt,
          setting_key:   'credit_charge'
        )

        if result[:success]
          self.add_credits({ credits_amt: })
          self.update(credit_charge_retry_level: self.auto_min_amount.to_i)

          response[:success]        = true
          response[:transaction_id] = result[:transaction_id]
        else
          response[:error_code]    = result[:error_code]
          response[:error_message] = result[:error_message]
          app_host                 = I18n.with_locale(self.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }

          self.update(credit_charge_retry_level: [(self.credit_charge_retry_level.to_i - 100), 10].max)

          Integrations::Slack::PostMessageJob.perform_later(
            token:   Rails.application.credentials[:slack][:token],
            channel: 'client-activity',
            content: "Client (#{self.name}) attempted to add credits to account (#{response[:error_message]&.humanize})."
          )
          ClientMailer.with(
            client_id:     self.id,
            amount:        charge_amt,
            charge_reason: 'credits',
            link_url:      Rails.application.routes.url_helpers.client_url(self, host: app_host)
          ).failed_charge_notification.deliver_later
        end
      end

      self.update(locked_at: nil) if ok2charge
    end

    response
  end

  # advance payment date to next month
  # client.advance_pmt_date!
  def advance_pmt_date!
    return if self.update(next_pmt_date: self.next_payment_date)

    errors = []

    self.errors.full_messages.each do |message|
      errors << "#{message}."
    end

    error = ClientPaymentDateNotAdvancedError.new("Client #{self.name} (#{self.id}) Payment Date NOT Advanced!")
    error.set_backtrace(BC.new.clean(caller))

    Appsignal.report_error(error) do |transaction|
      # Only needed if it needs to be different or there's no active transaction from which to inherit it
      Appsignal.set_action('Client.advance_pmt_date!')

      Appsignal.set_tags(
        error_level: 'error',
        error_code:  0
      )
      Appsignal.add_custom_data(
        client:    self.name,
        client_id: self.id,
        errors:    errors.inspect,
        file:      __FILE__,
        line:      __LINE__
      )
    end
  end

  def ai_agents?
    !self.aiagent_included_count.to_i.zero? && self.aiagents.any?
  end

  def aiagent_base_prorated_charge
    [self.prorated_ratio * self.aiagent_base_charge.to_d, 0.0].max
  end

  def aiagent_chargeable?
    self.aiagent_terms_accepted_at.present? && !Chronic.parse(self.aiagent_terms_accepted_at).nil? && !self.aiagent_included_count.to_i.zero?
  end

  def aiagent_free_remaining_count
    (self.aiagent_included_count.to_i + self.aiagent_overage_paid_count.to_i) - self.aiagents.count.to_i
  end

  def aiagent_free_remaining?
    self.aiagent_free_remaining_count.positive? || self.aiagent_included_count == -1
  end

  def aiagent_free_trial_start!
    self.aiagent_trial_started_at = Time.current
    self.aiagent_trial_ended_at = self.aiagent_trial_should_end_at
    self.save

    Integrations::Slack::PostMessageJob.perform_later(
      token:   Rails.application.credentials[:slack][:token],
      channel: 'client-activity',
      content: "Client (#{self.name}) signed up for AI Agent free trial."
    )

    # Schedule prorated trial ending
    self.delay(
      run_at:   self.aiagent_trial_ended_at,
      priority: DelayedJob.job_priority('aiagent_trial'),
      queue:    DelayedJob.job_queue('aiagent_trial'),
      process:  'aiagent_trial',
      data:     { client_id: self.id }
    ).aiagent_free_trial_end
  end

  # this function should be called when the Client's AI Agent trial period ends
  # it is queued up when a trial begins
  def aiagent_free_trial_end
    raise "AI Agent trial period has already been paid for client ##{self.id}" if self.aiagent_trial_paid_at
    raise "AI Agent trial period is not over for client ##{self.id}" if self.within_aiagent_promo_period?

    # charge prorated amount for aiagent_base_charge
    charge_amount = self.aiagent_base_prorated_charge
    res = self.charge_card(
      charge_amount:,
      setting_key:   'aiagent_base_charge'
    )

    unless res[:success]
      Integrations::Slack::PostMessageJob.perform_later(
        token:   Rails.application.credentials[:slack][:token],
        channel: 'client-activity',
        content: "AI Agent trial period unable to be paid for client ##{self.id}"
      )
      return
    end

    # mark client trial paid
    self.update(aiagent_trial_paid_at: Time.current)
  end

  # calculate the end date for an aiagent trial
  def aiagent_trial_should_end_at
    start_time = case self.aiagent_trial_started_at
                 when Time
                   self.aiagent_trial_started_at
                 when String
                   Chronic.parse(self.aiagent_trial_started_at)
                 end
    return nil unless start_time

    start_time + self.aiagent_trial_period_months.to_i.months + self.aiagent_trial_period_days.to_i.days
  end

  def aiagent_overage_count
    [self.aiagents.count - self.aiagent_included_count.to_i, 0].max
  end

  def aiagent_overage_prorated_charge
    [self.prorated_ratio * self.aiagent_overage_charge.to_d, 0.0].max
  end

  def campaign_collection(_skip_campaigns)
    self.campaigns.joins(:triggers).where(triggers: { trigger_type: [115, 120, 125, 130, 133, 134, 135, 136, 137, 138, 139, 140, 145] }).distinct.order(:name)
  end

  def campaign_collection_options(skip_campaigns)
    self.campaign_collection(skip_campaigns).pluck(:name, :id)
  end

  def campaigns_allowed?
    self.campaigns_count.positive?
  end

  # change a Client Package
  # client.change_package(package: Package/String/Integer, package_page: PackagePage/String/Integer)
  def change_package(args = {})
    package      = case args.dig(:package)
                   when Package
                     args[:package]
                   when String
                     Package.find_by(package_key: args.dig(:package))
                   else
                     Package.find_by(id: args.dig(:package).to_i)
                   end
    package_page = case args.dig(:package_page)
                   when PackagePage
                     args[:package_page]
                   when String
                     PackagePage.find_by(page_key: args.dig(:package_page))
                   else
                     PackagePage.find_by(id: args.dig(:package_page).to_i)
                   end
    response     = { success: false, error_message: '' }

    if package.is_a?(Package) && package_page.is_a?(PackagePage)

      if (self.next_pmt_date - Date.current).to_i <= 7
        # only charge a prorated charge if more than 7 days are remaining before next monthly payment
        self.update_package_settings(package_page:, package:)
        response[:success] = true
      else
        prorated_mo_charge = self.prorated_mo_charge(package:)

        if prorated_mo_charge > 0.50 # $0.50 is the minimum charge on our Stripe account

          if self.credit_card_on_file?
            result = self.charge_card(
              charge_amount: prorated_mo_charge,
              setting_key:   'mo_charge'
            )

            if result[:success]
              self.update_package_settings(package_page:, package:)
              response[:success] = true
            else
              Integrations::Slack::PostMessageJob.perform_later(
                token:   Rails.application.credentials[:slack][:token],
                channel: 'client-activity',
                content: "Client (#{self.name}) attempted to change package (#{response[:error_message]&.humanize})."
              )
              response[:error_message] = result[:error_message]
            end
          else
            response[:error_message] = 'Credit Card NOT on file.'
          end
        else
          self.update_package_settings(package_page:, package:)
          response[:success] = true
        end
      end
    else
      response[:error_message] = 'Unknown Package or PackagePage.'
    end

    response
  end

  # charge a card
  # client.charge_card(charge_amount: Decimal, setting_key: String)
  #   (req) charge_amount: (Decimal)
  #   (req) setting_key:   (String)
  def charge_card(args = {})
    charge_amount = args.dig(:charge_amount).to_d.round(2, half: :up)
    setting_key   = args.dig(:setting_key).to_s
    response      = { success: false, transaction_id: '', charge_amount: 0, error_code: '', error_message: '' }

    if charge_amount.positive? && setting_key.present?

      if self.credit_card_on_file?
        charge = Creditcard::Charge.create(client_id: self.client_token, amount: charge_amount, description: ClientTransaction::DESCRIPTIONS.dig(setting_key))

        if charge.valid? && charge.amount_captured == charge_amount
          # charge was successful
          ct = self.client_transactions.create(setting_key:, setting_value: charge.amount_captured, trans_id: charge.trans_id)
          response[:success]        = true
          response[:transaction_id] = ct.id
          response[:charge_amount]  = charge.amount_captured
        else
          Rails.logger.info "Client.charge_card: #{{ success: false, client_id: self.id, client_name: self.name, request_amount: charge_amount, charge_amount: charge.amount_captured, setting_key: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          response[:error_message] = charge.errors.full_messages.join(' ')
        end
      else
        response[:error_code]    = ''
        response[:error_message] = 'Credit card not on file. Please add Credit Card info.'

        Integrations::Slack::PostMessageJob.perform_later(
          token:   Rails.application.credentials[:slack][:token],
          channel: 'client-activity',
          content: "#{response[:error_message]}. Client: #{self.name}"
        )
      end
    else
      response[:error_code]    = ''
      response[:error_message] = "Invalid charge data. Please contact #{I18n.t('tenant.name')} support."

      Integrations::Slack::PostMessageJob.perform_later(
        token:   Rails.application.credentials[:slack][:token],
        channel: 'client-activity',
        content: "#{response[:error_message]}. Client: #{self.name}"
      )
    end

    response
  end

  # record transaction for Client (text, phone, rvm, etc)
  # client.charge_for_action(key: String, multiplier: Decimal)
  # client.charge_for_action(key: String, multiplier: Decimal, add_on: Decimal, contact_id: Integer, message_id: Integer)
  def charge_for_action(args = {})
    key                = args.dig(:key).to_s
    multiplier         = (args.dig(:multiplier) || 1).to_d
    add_on             = (args.dig(:add_on) || 0).to_d
    contact_id         = args.dig(:contact_id).to_i
    message_id         = args.dig(:message_id).to_i
    aiagent_id         = args.dig(:aiagent_id).to_i
    aiagent_session_id = args.dig(:aiagent_session_id).to_i

    return unless key.present? && multiplier.positive?

    if self.unlimited
      # charge 0 if Client set to unlimited
      charge = BigDecimal(0)
    else

      case key
      when 'aiagent_message_credits'
        charge = (self.send(key.to_s).to_d * multiplier) + add_on
      when 'text_message_credits'
        if self.text_segment_charge_type.zero?
          # charge fixed rate for all segments
          charge = [self.send(key.to_s).to_d * multiplier, self.send(key.to_s).to_d].max.floor(2) + add_on
        elsif self.text_segment_charge_type == 1
          # charge graduated rate for segments
          charge = [self.send(key.to_s).to_d + ((multiplier - BigDecimal(1)) * (self.send(key.to_s).to_d * BigDecimal('0.75'))), self.send(key.to_s).to_d].max.floor(2) + add_on
        end
      when 'phone_call_credits', 'video_call_credits'
        # charge by the minute for phone/video calls
        charge = [self.send(key.to_s).to_d * (multiplier / 60), self.send(key.to_s).to_d].max.floor(2) + add_on
      when # 'aiagent_message_credits', 'text_image_credits', 'rvm_credits'
        # TODO: do not use self.send in a case else; this is risky
        # charge for an image in a text message, ringless or flat fee
        charge = self.send(key.to_s).to_d + add_on
      end
    end

    self.deduct_credits(credits_amt: charge, key:, contact_id:, message_id:, aiagent_id:, aiagent_session_id:)

    # recharge for credits if necessary
    self.recharge_credits
  end

  # charge initial charges when creating new account
  # client.charge_for_startup
  def charge_for_startup
    setup_amount = self.setup_fee.to_d
    mo_amount    = if (self.first_payment_delay_days + self.first_payment_delay_months).zero?
                     self.current_mo_charge.to_d
                   else
                     0
                   end
    response     = { success: false, error_message: '' }

    if (setup_amount + mo_amount).positive?
      # Client monthly charge + setup fee is greater than $0.00

      result = self.charge_card(
        charge_amount: (setup_amount + mo_amount),
        setting_key:   'startup_costs'
      )

      if result[:success]
        # charge was successful
        response[:success] = true
        self.advance_pmt_date!

        if self.fp_affiliate.present?
          package = Package.find_by(id: self.package_id)
          FirstPromoter.new.register_sale(client_id: self.id, client_name: "#{self.users.first.fullname} (#{self.name})", transaction_id: result[:transaction_id], package_key: (package ? package.package_key : ''), amount: ((setup_amount + mo_amount) * 100).to_i, monthly_charge: (mo_amount * 100).to_i)
        end
      else
        # charge was NOT successful
        Integrations::Slack::PostMessageJob.perform_later(
          token:   Rails.application.credentials[:slack][:token],
          channel: 'client-activity',
          content: "Client (#{self.name}) attempted to create a new account (#{response[:error_message]&.humanize})."
        )
        response[:error_message] = result[:error_message]
      end
    else
      # Client has $0.00 charges
      response[:success] = true
      self.advance_pmt_date!
    end

    response
  end

  # charge monthly fees on all accounts
  # Client.charge_monthly_accounts
  def self.charge_monthly_accounts
    Client.where(next_pmt_date: ..Date.current).where('data @> ?', { active: true }.to_json).find_each do |client|
      charge_amt = client.current_mo_charge.to_d

      if client.mo_charge_retry_count.to_i.between?(5, 10)
        # skip attempts for monthly charge for 7 days
        client.update(mo_charge_retry_count: client.mo_charge_retry_count.to_i + 1)
      elsif client.mo_charge_retry_count.to_i < 12 && client.charge_monthly_fee
        # monthly charge was successful
        # reset retry count to 0
        client.update(mo_charge_retry_count: 0, next_pmt_date: client.next_payment_date(3.days.from_now), aiagent_overage_paid_count: client.aiagent_overage_count)
      else
        # monthly charge was NOT successful
        # increase retry count by 1
        client.update(mo_charge_retry_count: client.mo_charge_retry_count.to_i + 1)

        tenant_name         = I18n.with_locale(client.tenant) { I18n.t('tenant.name') }
        tenant_phone_number = I18n.with_locale(client.tenant) { I18n.t("tenant.#{Rails.env}.phone_number") }
        app_host            = I18n.with_locale(client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }

        case client.mo_charge_retry_count.to_i
        when 1
          # notify Client of first failed attempt
          ClientMailer.with(
            client_id:     client.id,
            amount:        charge_amt,
            charge_reason: 'monthly due',
            content:       "#{tenant_name} 1st Credit Card attempt failed. We will try again tomorrow.",
            link_url:      Rails.application.routes.url_helpers.client_url(client, host: app_host)
          ).failed_charge_notification.deliver_later
        when 2
          # notify Client of second failed attempt
          ClientMailer.with(
            client_id:     client.id,
            amount:        charge_amt,
            charge_reason: 'monthly due',
            content:       "#{tenant_name} 2nd Credit Card attempt failed. Please update your credit card information.",
            link_url:      Rails.application.routes.url_helpers.client_url(client, host: app_host)
          ).failed_charge_notification.deliver_later
        when 3
          # notify Client of third failed attempt
          ClientMailer.with(
            client_id:     client.id,
            amount:        charge_amt,
            charge_reason: 'monthly due',
            content:       "#{tenant_name} 3rd Credit Card attempt failed. Your account may be closed. A closed account deletes all Contacts. Please contact us at #{ActionController::Base.helpers.number_to_phone(tenant_phone_number)}.",
            link_url:      Rails.application.routes.url_helpers.client_url(client, host: app_host)
          ).failed_charge_notification.deliver_later
        when 4
          # notify Client of fourth failed attempt
          ClientMailer.with(
            client_id:     client.id,
            amount:        charge_amt,
            charge_reason: 'monthly due',
            content:       "#{tenant_name} 4th Credit Card attempt failed. Your account is subject to closure. A closed account cancels all Campaigns. Please contact us at #{ActionController::Base.helpers.number_to_phone(tenant_phone_number)}.",
            link_url:      Rails.application.routes.url_helpers.client_url(client, host: app_host)
          ).failed_charge_notification.deliver_later
        when 5
          # notify Client of fifth failed attempt
          ClientMailer.with(
            client_id:     client.id,
            amount:        charge_amt,
            charge_reason: 'monthly due',
            content:       "#{tenant_name} 5th Credit Card attempt failed. Your account will be closed after one additional attempt. A closed account deletes all automated features. Please contact us at #{ActionController::Base.helpers.number_to_phone(tenant_phone_number)} immediately.",
            link_url:      Rails.application.routes.url_helpers.client_url(client, host: app_host)
          ).failed_charge_notification.deliver_later
        else
          Integrations::Slack::PostMessageJob.perform_later(
            token:   Rails.application.credentials[:slack][:token],
            channel: 'client-activity',
            content: "Six attempts have been made over 2 weeks to charge Client's credit card for monthly fees. All attempts have failed. Please contact #{client.name} or cancel account."
          )
        end
      end
    end
  end

  # charge monthly fee
  # client.charge_monthly_fee
  def charge_monthly_fee
    response = false

    if self.active? && self.current_mo_charge.to_d.positive? && Date.current >= self.first_payment_date
      result = self.charge_card(
        charge_amount: self.current_mo_charge.to_d,
        setting_key:   'mo_charge'
      )

      if result[:success]
        # charge was successful
        response = true
        self.advance_pmt_date!
        self.add_credits({ credits_amt: self.current_mo_credits.to_d }) unless self.unlimited

        if self.fp_affiliate.present?
          package = Package.find_by(id: self.package_id)
          FirstPromoter.new.register_sale({ client_id: self.id, client_name: "#{self.users.first.fullname} (#{self.name})", transaction_id: result[:transaction_id], package_key: (package ? package.package_key : ''), amount: (self.current_mo_charge.to_d * 100).to_i, monthly_charge: (self.current_mo_charge.to_d * 100).to_i })
        end
      else
        Integrations::Slack::PostMessageJob.perform_later(
          token:   Rails.application.credentials[:slack][:token],
          channel: 'client-activity',
          content: "Attempted to charge monthly charges to Client (#{self.name}) for account (#{result[:error_message]&.humanize})."
        )
      end
    else
      # Client is inactive or has $0.00 monthly fee due
      response = true
      self.advance_pmt_date!
    end

    response
  end

  def contact_matching_with_email?
    self.contact_matching_with_email.nil? ? true : self.contact_matching_with_email
  end

  def contact_phone_labels_for_select
    self.contact_phone_labels.map { |label| [label.capitalize, label] }.sort_by { |label| label[0] }
  end

  # return a matching Corporate (Brand) Contact for Client
  # corp_contact = @client.corp_contact
  def corp_contact
    Client.find_by(id: I18n.with_locale(self.tenant) { I18n.t("tenant.#{Rails.env}.client_id") })&.contacts&.find_by(id: self.contact_id)
  end

  # find or create a matching Corporate (Brand) Contact for Client
  # corp_contact = @client.create_corp_contact
  def create_corp_contact
    tenant_client_id = I18n.with_locale(self.tenant) { I18n.t("tenant.#{Rails.env}.client_id") }
    corp_contact     = nil

    if (corp_client = Client.find_by(id: tenant_client_id))
      user = self.users.order(:id).first

      if user
        corp_contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: corp_client.id, phones: { self.phone => 'mobile' }, emails: [user.email])
        corp_contact.update(
          firstname: user.firstname,
          lastname:  user.lastname,
          address1:  self.address1,
          address2:  self.address2,
          city:      self.city,
          state:     self.state,
          zipcode:   self.zip,
          email:     user.email,
          ok2text:   1,
          ok2email:  1
        )

        self.update(contact_id: corp_contact.id)
      end
    end

    corp_contact
  end

  # create customer at credit card processor
  # Client.create_credit_card_customer
  def create_credit_card_customer
    response = { success: false, error_message: '' }

    # create a Client token from new card token
    customer = Creditcard::Customer.create(
      card_id:          self.card_token,
      cust_description: self.name + " (#{self.phone})",
      email:            self.def_user&.email,
      name:             self.name
    )

    if customer.valid?
      # credit card customer was created
      self.update(
        card_token:   customer.card_id.to_s,
        client_token: customer.client_id.to_s
      )

      response[:success] = true
    else
      # credit card customer id was NOT created
      response[:error_message] = customer.errors.full_messages
    end

    response
  end

  # determine if Client has a valid credit card on file
  # client.credit_card_on_file?
  def credit_card_on_file?
    self.client_token.present?
  end

  # determine if Client current credits are dangerously low (below $5.00)
  # client.credits_in_danger
  def credits_in_danger?
    self.active? && !self.unlimited && (self.current_balance.to_d / 100) < self.auto_min_amount
  end

  # process one set of rows of an imported CSV file
  # client.csv_row_import(row: Hash, overwrite: Boolean, tag_id: Integer)
  def csv_row_process(args = {})
    batch_rows           = args.dig(:batch_rows) && args[:batch_rows].is_a?(Array) ? args[:batch_rows] : []
    user_id              = (args.dig(:user_id) || self.def_user_id).to_i
    overwrite            = args.dig(:overwrite).to_bool
    group_id             = args.dig(:group_id).to_i
    tag_id               = args.dig(:tag_id).to_i
    current_user_id      = args.dig(:current_user_id).to_i
    header_fields        = args.dig(:header_fields) || {}

    header_fields_inverted = header_fields.invert.symbolize_keys
    custom_fields          = self.client_custom_fields.pluck(:var_var, :id).to_h
    yes_options            = %w[1 y yes ok]

    batch_rows.each do |row|
      working_row = {}
      working_row[:user_id]      = user_id
      working_row[:companyname]  = header_fields_inverted.include?(:companyname) ? row[header_fields_inverted[:companyname].to_i].to_s.remove_tags : nil
      fullname                   = header_fields_inverted.include?(:fullname) ? row[header_fields_inverted[:fullname].to_i].to_s.remove_tags.parse_name : { firstname: '', lastname: '' }
      working_row[:firstname]    = header_fields_inverted.include?(:firstname) && row[header_fields_inverted[:firstname].to_i].to_s.present? ? row[header_fields_inverted[:firstname].to_i].to_s.remove_tags : nil
      working_row[:firstname]    = working_row[:firstname].nil? && fullname && (fullname[:firstname].present? || fullname[:suffix].present?) ? [fullname[:firstname], fullname[:suffix]].compact_blank.join(', ') : working_row[:firstname]
      working_row[:lastname]     = header_fields_inverted.include?(:lastname) && row[header_fields_inverted[:lastname].to_i].to_s.present? ? row[header_fields_inverted[:lastname].to_i].to_s.remove_tags : nil
      working_row[:lastname]     = working_row[:lastname].nil? && fullname && fullname[:lastname].present? ? fullname[:lastname] : working_row[:lastname]
      working_row[:address1]     = header_fields_inverted.include?(:address1) ? row[header_fields_inverted[:address1].to_i].to_s.remove_tags : nil
      working_row[:address2]     = header_fields_inverted.include?(:address2) ? row[header_fields_inverted[:address2].to_i].to_s.remove_tags : nil
      working_row[:city]         = header_fields_inverted.include?(:city) ? row[header_fields_inverted[:city].to_i].to_s.remove_tags : nil
      working_row[:state]        = header_fields_inverted.include?(:state) ? row[header_fields_inverted[:state].to_i].to_s.remove_tags : nil
      working_row[:zipcode]      = header_fields_inverted.include?(:zipcode) ? row[header_fields_inverted[:zipcode].to_i].to_s.remove_tags : nil
      working_row[:birthdate]    = header_fields_inverted.include?(:birthdate) ? Chronic.parse(row[header_fields_inverted[:birthdate].to_i].to_s.remove_tags)&.to_date : nil
      email                      = header_fields_inverted.include?(:email) ? row[header_fields_inverted[:email].to_i].to_s.remove_tags : nil
      working_row[:ok2text]      = if header_fields_inverted.include?(:ok2text)
                                     yes_options.include?(row[header_fields_inverted[:ok2text].to_i].to_s.downcase.remove_tags) ? 1 : 0
                                   end
      working_row[:ok2email]     = if header_fields_inverted.include?(:ok2email)
                                     yes_options.include?(row[header_fields_inverted[:ok2email].to_i].to_s.downcase.remove_tags) ? 1 : 0
                                   end

      # take the first email if comma separated
      email               = email.split(%r{[\s,;]}).map { |e| e if URI::MailTo::EMAIL_REGEXP.match?(e) }.compact_blank if email.present?
      working_row[:email] = email[0] if email.present?

      ext_refs = {}

      ApplicationController.helpers.ext_references_options(self).to_h { |e| ["contact-#{e[1]}-id", "Contact #{e[0]} ID"] }.each_key do |k|
        ext_refs[k.sub('contact-', '').sub('-id', '')] = row[header_fields_inverted[k.to_sym].to_i].to_s.remove_tags if header_fields_inverted.include?(k.to_sym) && row[header_fields_inverted[k.to_sym].to_i].to_s.present?
      end

      all_phones = {}

      ::Webhook.internal_key_hash(self, 'contact', %w[phones]).each_key do |label|
        if header_fields_inverted.include?(label.to_sym)
          phone = row[header_fields_inverted[label.to_sym].to_i].to_s.remove_tags.clean_phone(self.primary_area_code)
          all_phones[phone] = label.gsub('phone_', '') unless phone.empty?
        end
      end

      working_row.each do |key, value|
        working_row.delete(key) if value.nil? || value.to_s.empty?
      end

      if working_row[:firstname].present? || working_row[:lastname].present? || all_phones.present? || working_row.dig(:email).present? || working_row.dig(:companyname).present?
        contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(
          client_id: self.id,
          phones:    all_phones,
          emails:    [working_row.dig(:email).to_s],
          ext_refs:
        )

        # allow the first name to remain as default 'Friend' if both first & last name are empty
        working_row.delete(:firstname) if working_row.dig(:firstname).to_s.empty? && working_row.dig(:lastname).to_s.empty?

        working_row[:ok2text]  = working_row[:ok2text] || contact.ok2text
        working_row[:ok2email] = working_row[:ok2email] || contact.ok2email

        if contact && (contact.new_record? || overwrite) && contact.update(working_row)
          update_custom_fields = {}

          header_fields.each do |key, value|
            if value == 'tag'

              row[key.to_i].to_s.split(',').each do |tag_name|
                # data included a Tag
                if tag_name.strip.present? && (tag = self.tags.find_or_create_by(name: tag_name.strip))
                  Contacts::Tags::ApplyJob.perform_now(
                    contact_id: contact.id,
                    tag_id:     tag.id
                  )
                end
              end
            elsif custom_fields.key?(value)
              update_custom_fields[custom_fields[value]] = row[key.to_i].to_s
            end
          end

          # save ContactCustomFields if selected
          contact.update_custom_fields(custom_fields: update_custom_fields) if update_custom_fields.present?

          contact.process_actions(
            group_id:,
            tag_id:
          )
        end
      end
    end

    return unless current_user_id.positive? && (user = User.find_by(id: current_user_id))

    contacts_waiting = [DelayedJob.scheduled_imports(current_user_id).count - 1, 0].max * 100

    # add new message to div
    html = ApplicationController.render partial: 'contacts/import/form', locals: { user: }
    UserCable.new.broadcast 0, user, { id: "contacts_import_form_#{user.id}", append: 'false', scrollup: 'false', html: }

    return unless contacts_waiting.zero?

    Users::SendPushJob.perform_later(
      content: 'Your CSV file import has completed!',
      title:   'CSV File',
      user_id: user.id
    )
  end

  def current_credit_charge
    self.within_promo_period? ? self.promo_credit_charge : self.credit_charge
  end

  def current_max_phone_numbers
    self.within_promo_period? ? self.promo_max_phone_numbers : self.max_phone_numbers
  end

  def current_mo_charge
    self.within_promo_period? ? self.promo_mo_charge.to_d + self.current_mo_aiagent_charge.to_d : self.mo_charge.to_d + self.current_mo_aiagent_charge.to_d
  end

  def current_mo_aiagent_charge
    return 0.0 unless self.aiagent_chargeable?

    self.within_aiagent_promo_period? ? self.current_aiagent_overage_charge.to_d : self.aiagent_base_charge.to_d + self.current_aiagent_overage_charge.to_d
  end

  def current_aiagent_overage_charge
    [self.aiagent_overage_count * self.aiagent_overage_charge.to_d, 0.0].max
  end

  def current_mo_credits
    self.within_promo_period? ? self.promo_mo_credits : self.mo_credits
  end

  # deactivate a Client
  # client.deactivate
  def deactivate(user:)
    # stop all Campaigns in progress
    Contact.where(client_id: self.id).joins(:contact_campaigns).where(contact_campaigns: { completed: false }).pluck(:id).uniq.in_groups_of(50, false).each do |contacts|
      MyContacts::GroupActionBlockJob.perform_later(
        user_id:       user.id,
        process:       'group_stop_campaign',
        group_process: 1,
        data:          { action: 'stop_campaign', stop_campaign_id: 'all', contacts: }
      )
    end

    # deactivate all Campaigns
    # rubocop:disable Rails/SkipsModelValidations
    self.campaigns.where(active: true).update_all(active: false)
    # rubocop:enable Rails/SkipsModelValidations

    # delete all remaining DelayedJobs
    DelayedJob.where(contact_id: self.contacts.pluck(:id)).delete_all

    # delete phone numbers
    self.twnumbers.destroy_all

    # ste all 10DLC campaigns to not renew
    tcr_client = ::Dlc10::CampaignRegistry::V2::Base.new

    self.dlc10_brand&.campaigns&.find_each do |dlc10_campaign|
      dlc10_campaign.auto_renewal = false
      tcr_client.campaign_update(campaign: JSON.parse(dlc10_campaign.to_json).symbolize_keys)

      if tcr_client.success?
        dlc10_campaign.save
      else
        JsonLog.info 'Client.deactivate', { message: 'Auto-renewal of a 10DLC Campaign could not be set to False', client_name: self.name }, client_id: self.id
      end
    end

    JsonLog.info 'Client.deactivate', { message: 'A Client was deactivated', client_name: self.name, mo_charge: self.mo_charge }
  end

  # deduct credits from a Client account
  # client.deduct_credits(credits_amt: Integer, key: String, contact_id: Integer, message_id: Integer, aiagent_id: Integer, aiagent_session_id: Integer)
  def deduct_credits(args = {})
    credits_amt = args.dig(:credits_amt).to_d

    return unless credits_amt.positive? && !self.unlimited

    # rubocop:disable Rails/SkipsModelValidations
    Client.where(id: self.id).update_all("current_balance = current_balance - #{(credits_amt * BigDecimal(100)).to_i}")
    # rubocop:enable Rails/SkipsModelValidations
    self.client_transactions.create(setting_key: args.dig(:key).to_s, setting_value: credits_amt, contact_id: args.dig(:contact_id).to_i, message_id: args.dig(:message_id).to_i, aiagent_id: args.dig(:aiagent_id).to_i, aiagent_session_id: args.dig(:aiagent_session_id).to_i)
    self.reload
  end

  def def_user_name
    self.users.find_by(id: self.def_user_id)&.fullname || 'Unknown'
  end

  # determine next Client payment
  # client.first_payment_date
  def first_payment_date
    (self.created_at || Date.current).to_date + self.first_payment_delay_days.days + self.first_payment_delay_months.months
  end

  def group_collection(skip_groups)
    self.groups.where.not(id: skip_groups).order(:name)
  end

  def group_collection_options(create_new, skip_groups)
    (create_new ? [['Create New Group', 0]] : []).concat(self.group_collection(skip_groups).pluck(:name, :id))
  end

  def groups_allowed?
    self.groups_count.positive?
  end

  # create array of arrays with each keyword Trigger statistic
  # Client.keyword_trigger_stats from_date_to_date
  def keyword_trigger_stats(from_date, to_date, campaign_id = 0)
    client_campaigns = if campaign_id.to_i.zero?
                         self.campaigns.pluck(:id)
                       else
                         self.campaigns.where(id: campaign_id.to_i).pluck(:id)
                       end

    # collect all Client keyword Triggers
    keyword_triggers = Trigger.where(campaign_id: client_campaigns).where(trigger_type: 110).pluck(:id).compact
    # collect all Client keyword Triggeractions
    keyword_triggeractions = Triggeraction.where(trigger_id: keyword_triggers).pluck(:id, :trigger_id).to_h
    # count all Contacts::Campaign TriggerActions
    contact_campaign_triggeractions = Contacts::Campaign::Triggeraction.where(triggeraction_id: keyword_triggeractions.keys).where(created_at: from_date..to_date).group(:triggeraction_id).count

    keywords_completed = []
    keyword_triggers.each do |t|
      count = 0
      keyword_triggeractions.filter_map { |k, v| k if v.to_i == t.to_i }.each { |x| count = [count, contact_campaign_triggeractions[x] || 0].max }
      keywords_completed << [Trigger.find_by(id: t.to_i).campaign.id, Trigger.find_by(id: t.to_i).campaign.name, count]
    end

    keywords_completed
  end

  # return the last date a promotional payment will be charged
  # client.last_promo_payment_date
  def last_promo_payment_date
    self.first_payment_date + (self.promo_months - 1).months
  end

  # count new Contacts for a specified period
  # @client.new_contact_count user_id, from_date, to_date
  def new_contact_count(user_id, from_date, to_date)
    contacts = self.contacts.where(created_at: from_date..to_date)
    contacts = contacts.where(user_id: user_id.to_i) unless user_id.to_i.zero?
    contacts.count
  end

  # count new Messages::Messages received for a specified period
  # @client.new_message_receive_count from_date, to_date
  def new_message_receive_count(from_date, to_date)
    Messages::Message.where(created_at: from_date..to_date).where.not(from_phone: [self.twnumbers.pluck(:phonenumber)]).joins(:contact).where(contacts: { client_id: self.id }).count
  end

  # determine next Client payment
  # client.next_payment_date
  # (opt) current_date: (Date)
  def next_payment_date(current_date = Date.current)
    self.first_payment_date + (((current_date.year * 12) + current_date.month) - ((self.first_payment_date.year * 12) + self.first_payment_date.month) + (self.first_payment_date.day <= current_date.day ? 1 : 0)).months
  end

  def next_payment_due
    self.within_promo_period?(self.next_payment_date) ? self.promo_mo_charge : self.mo_charge
  end

  # send notifications to admins (push notification or text)
  # client.notify_admins( content: String )
  def notify_admins(args = {})
    content             = args.dig(:content).to_s
    tenant_phone_number = I18n.with_locale(self.tenant) { I18n.t("tenant.#{Rails.env}.phone_number") }

    User.client_admins(self.id).each do |user|
      Users::SendPushOrTextJob.perform_later(
        content:,
        from_phone: tenant_phone_number,
        to_phone:   user.phone,
        user_id:    user.id
      )
    end
  end

  def ok_to_push_to_vitally?
    self.mo_charge.to_d >= 500.0 && !Rails.env.test?
  end

  # verify that Client's current Package is upgradable
  # client.package_upgradable?
  def package_upgradable?
    if self.package_id && self.package_page_id && (package_page = PackagePage.find_by(id: self.package_page_id))
      (package_page.package_01_id == self.package_id && (package_page.package_02_id + package_page.package_03_id + package_page.package_04_id).positive?) ||
        (package_page.package_02_id == self.package_id && (package_page.package_03_id + package_page.package_04_id).positive?) ||
        (package_page.package_03_id == self.package_id && package_page.package_04_id.positive?)
    else
      false
    end
  end

  def prorated_ratio
    days_used      = Date.current - (self.next_pmt_date - 1.month)
    days_remaining = self.next_pmt_date - Date.current
    days_remaining.to_i.to_d / (days_used.to_i.to_d + days_remaining.to_i.to_d)
  end

  # client.prorated_mo_charge(package: Package/String/Integer, package_page: PackagePage/String/Integer)
  def prorated_mo_charge(args = {})
    package = case args.dig(:package)
              when Package
                args[:package]
              when String
                Package.find_by(package_key: args.dig(:package))
              else
                Package.find_by(id: args.dig(:package).to_i)
              end

    new_mo_charge  = package.within_promo_period?(self.first_payment_date) ? package.promo_mo_charge.to_d : package.mo_charge.to_d

    [((self.prorated_ratio * new_mo_charge) - (self.prorated_ratio * self.current_mo_charge.to_d)).round(2), 0.0].max
  end

  # recharge all Client accounts below minimums set by Clients
  # Client.recharge_all_accounts
  def self.recharge_all_credits
    Client.find_each(&:recharge_credits)
  end

  # recharge a Client if auto-recharge and credits are below minimum set by Client
  # client.recharge_credits
  def recharge_credits
    self.add_credits_by_charge(credits_amt: self.auto_add_amount) if self.auto_recharge && self.credits_in_danger?
  end

  def send_emails?
    # Can this client send emails?
    Email::Base.client_send_emails?(self)
  end
  alias send_email? send_emails?

  def sendgrid_api_key
    # find SendGrid API Key for Client
    ClientApiIntegration.find_by(client_id: self.id, target: 'sendgrid')&.api_key.to_s
  end

  def stages_allowed?
    self.stages_count.positive?
  end

  def tag_collection(skip_tags)
    self.tags.where.not(id: skip_tags).order('LOWER(name) ASC')
  end

  def tag_collection_options(create_new, skip_tags)
    (create_new ? [['Create New Tag', 0]] : []).concat(self.tag_collection(skip_tags).pluck(:name, :id))
  end

  # convert a time from UTC by Client time zone
  # @client.time_to_local( utc_time )
  def time_to_local(utc_time)
    utc_time.in_time_zone(self.time_zone)
  end

  # convert a time entered by Client in Client time zone to UTC
  # @client.time_to_utc( client_time )
  def time_to_utc(client_time)
    if client_time.to_s.empty?
      Time.current
    else
      Time.zone = self.time_zone
      Time.zone.strptime(client_time, '%m/%d/%Y %I:%M %p').utc
    end
  end

  # update Client labels for phone numbers
  #   (opt) new_label: (String) new_label that was given to a newly created ContactPhone
  def update_client_labels(new_label: nil)
    if new_label.present?
      # we can optimize here since we know the new_label is from a brand new ContactPhone
      self.update(contact_phone_labels: self.contact_phone_labels.push(new_label)) if self.contact_phone_labels.exclude?(new_label)
    else
      # we need to find all currently in use labels
      self.update(contact_phone_labels: ContactPhone.client_labels(self.id))
    end
  end

  # update Client credit card info from credit card processor
  # Client.update_credit_card
  def update_credit_card
    response = { success: false, error_message: '' }

    # get the current card info
    if (card = Creditcard::Card.find_by(card_id: self.card_token, client_id: self.client_token))
      # credit card info was retrieved
      self.update(
        card_token:     card.card_id.to_s,
        card_brand:     card.card_brand.to_s,
        card_last4:     card.card_last4.to_s,
        card_exp_month: card.card_exp_month.to_s,
        card_exp_year:  card.card_exp_year.to_s
      )

      response[:success] = true
    else
      # credit card info was NOT retrieved
      response[:error_message] = 'Credit card was not found'
    end

    response
  end

  # update the default User for this Client
  # @client.update_def_user_id [excluded_user_ids]
  def update_def_user_id(excluded_user_ids)
    excluded_user_ids = [] unless excluded_user_ids.is_a?(Array)

    # find an admin for this Client
    admin_user = self.users.where.not(id: excluded_user_ids).where('permissions @> ?', { users_controller: ['permissions'] }.to_json).first

    # find any User if admin User was not found
    admin_user ||= self.users.where.not(id: excluded_user_ids).first

    if admin_user.nil?
      false
    else
      # assign User to Client as default User for all new Contacts
      self.update(def_user_id: admin_user.id)
    end
  end

  # update all Client settings for selected Package
  # @client.update_package_settings(package: Package/String/Integer, package_page: PackagePage/String/Integer)
  def update_package_settings(args = {})
    package      = case args.dig(:package)
                   when Package
                     args[:package]
                   when String
                     Package.find_by(package_key: args.dig(:package))
                   else
                     Package.find_by(id: args.dig(:package).to_i)
                   end
    package_page = case args.dig(:package_page)
                   when PackagePage
                     args[:package_page]
                   when String
                     PackagePage.find_by(page_key: args.dig(:package_page))
                   else
                     PackagePage.find_by(id: args.dig(:package_page).to_i)
                   end

    return unless package

    package_page ||= package.package_pages_01.first
    package_page ||= package.package_pages_02.first
    package_page ||= package.package_pages_03.first
    package_page ||= package.package_pages_04.first

    return unless package_page

    # Client Settings
    self.my_agencies                           = package.agency_ids&.map(&:to_i)&.compact_blank || []
    self.credit_charge                         = package.credit_charge.to_d
    self.dlc10_charged                         = package.dlc10_charged.to_bool
    self.first_payment_delay_days              = package.first_payment_delay_days.to_i
    self.first_payment_delay_months            = package.first_payment_delay_months.to_i
    self.max_phone_numbers                     = package.max_phone_numbers.to_i
    self.mo_charge                             = package.mo_charge.to_d
    self.mo_credits                            = package.mo_credits.to_d
    self.onboarding_scheduled                  = nil
    self.package_id                            = package.id
    self.package_page_id                       = package_page.id
    self.affiliate_id                          = package.affiliate_id
    self.promo_credit_charge                   = package.promo_credit_charge.to_d
    self.promo_max_phone_numbers               = package.promo_max_phone_numbers.to_i
    self.promo_mo_charge                       = package.promo_mo_charge.to_d
    self.promo_mo_credits                      = package.promo_mo_credits.to_d
    self.promo_months                          = package.promo_months.to_i
    self.searchlight_fee                       = package.searchlight_fee.to_d
    self.setup_fee                             = package.setup_fee.to_d
    self.trial_credits                         = package.trial_credits.to_d
    self.unlimited                             = false

    # Client Features
    self.aiagent_included_count                = package.aiagent_included_count.to_i
    self.aiagent_base_charge                   = package.aiagent_base_charge.to_d
    self.aiagent_overage_charge                = package.aiagent_overage_charge.to_d
    self.aiagent_message_credits               = package.aiagent_message_credits.to_d
    self.aiagent_trial_period_days             = package.aiagent_trial_period_days.to_i
    self.aiagent_trial_period_months           = package.aiagent_trial_period_months.to_i
    self.share_aiagents_allowed                = package.share_aiagents_allowed
    self.campaigns_count                       = package.campaigns_count.to_i
    self.custom_fields_count                   = package.custom_fields_count.to_i
    self.dlc10_required = package.dlc10_required.to_bool
    self.folders_count                         = package.folders_count.to_i
    self.groups_count                          = package.groups_count.to_i
    self.max_email_templates                   = package.max_email_templates.to_i
    self.import_contacts_count                 = package.import_contacts_count.to_i
    self.integrations_allowed                  = [package.integrations_allowed || []].flatten
    self.max_contacts_count                    = package.max_contacts_count.to_i
    self.max_kpis_count                        = package.max_kpis_count.to_i
    self.max_users_count                       = package.max_users_count.to_i
    self.max_voice_recordings                  = package.max_voice_recordings.to_i
    self.message_central_allowed               = package.message_central_allowed.to_bool
    self.my_contacts_allowed                   = package.my_contacts_allowed.to_bool
    self.my_contacts_group_actions_all_allowed = package.my_contacts_group_actions_all_allowed.to_bool
    self.phone_call_credits                    = package.phone_call_credits.to_d
    self.phone_calls_allowed                   = package.phone_calls_allowed.to_bool
    self.phone_vendor                          = package.phone_vendor
    self.quick_leads_count                     = package.quick_leads_count.to_i
    self.rvm_allowed                           = package.rvm_allowed.to_bool
    self.rvm_credits                           = package.rvm_credits.to_d
    self.share_aiagents_allowed                = package.share_aiagents_allowed.to_bool
    self.share_email_templates_allowed         = package.share_email_templates_allowed.to_bool
    self.share_funnels_allowed                 = package.share_funnels_allowed.to_bool
    self.share_quick_leads_allowed             = package.share_quick_leads_allowed.to_bool
    self.share_surveys_allowed                 = package.share_surveys_allowed.to_bool
    self.share_widgets_allowed                 = package.share_widgets_allowed.to_bool
    self.share_stages_allowed                  = package.share_stages_allowed.to_bool
    self.stages_count                          = package.stages_count.to_i
    self.surveys_count                         = package.surveys_count.to_i
    self.tasks_allowed                         = package.tasks_allowed.to_bool
    self.text_image_credits                    = package.text_image_credits.to_d
    self.text_message_credits                  = package.text_message_credits.to_d
    self.text_message_images_allowed           = package.text_message_images_allowed.to_bool
    self.text_segment_charge_type              = package.text_segment_charge_type.to_i
    self.trackable_links_count                 = package.trackable_links_count.to_i
    self.training                              = [package.training || []].flatten
    self.user_chat_allowed                     = package.user_chat_allowed.to_bool
    self.video_call_credits                    = package.video_call_credits.to_d
    self.video_calls_allowed                   = package.video_calls_allowed.to_bool
    self.widgets_count                         = package.widgets_count.to_i

    # Client Billing
    self.auto_recharge                         = true
    self.auto_min_amount                       = (BigDecimal(5) / self.credit_charge.to_d).to_i
    self.auto_add_amount                       = (BigDecimal(25) / self.credit_charge.to_d).to_i

    self.save
  end

  def usa?
    ApplicationController.helpers.us_states_array.pluck(1).include?(self.state)
  end

  def voice_recording_options
    VoiceRecording.by_client(self.id).order(:recording_name).pluck(:recording_name, :id)
  end

  def within_aiagent_promo_period?(time = Time.current)
    return false unless self.aiagent_trial_ended_at
    return false unless Chronic.parse(self.aiagent_trial_ended_at).is_a?(Time)

    Chronic.parse(self.aiagent_trial_ended_at).beginning_of_day > time.beginning_of_day
  end

  def within_promo_period?(date = Date.current)
    self.promo_months.positive? && date < self.last_promo_payment_date + 1.month
  end

  private

  # advance payment date to next month
  # client.advance_pmt_date
  def advance_pmt_date
    self.next_pmt_date = self.next_payment_date
  end

  def after_create_commit_actions
    super

    Integration::Vitally::V2024::Base.new.client_push(self.id) if self.ok_to_push_to_vitally?
  end

  def after_update_commit_actions
    super

    Integration::Vitally::V2024::Base.new.client_push(self.id) if self.name_previously_changed? && self.ok_to_push_to_vitally?
  end

  def apply_defaults
    # Client Settings
    self.active                                           = self.active.nil? ? true : self.active.to_bool
    self.agency_access                                    = self.agency_access.nil? ? false : self.agency_access
    self.contact_matching_with_email                      = self.contact_matching_with_email.nil? ? true : self.contact_matching_with_email
    self.contact_matching_ignore_emails                 ||= []
    self.credit_charge                                  ||= BigDecimal('0.04')
    self.credit_charge_retry_level                      ||= (BigDecimal(5) / self.credit_charge.to_d).to_i
    self.dlc10_charged                                  ||= true
    self.domains                                        ||= {}
    self.first_payment_delay_days                       ||= 0
    self.first_payment_delay_months                     ||= 0
    self.fp_affiliate                                   ||= ''
    self.max_phone_numbers                              ||= 1 # existing
    self.mo_charge                                      ||= BigDecimal(0)
    self.mo_charge_retry_count                          ||= 0
    self.mo_credits                                     ||= BigDecimal(0)
    self.my_agencies                                    ||= [2] # Clients approved to access this Client
    self.onboarding_scheduled                           ||= nil
    self.affiliate_id                                   ||= nil
    self.primary_area_code                              ||= self.phone.to_s[0, 3].presence || '801'
    self.promo_credit_charge                            ||= BigDecimal('0.04')
    self.promo_max_phone_numbers                        ||= 0
    self.promo_mo_charge                                ||= BigDecimal(0)
    self.promo_mo_credits                               ||= BigDecimal(0)
    self.promo_months                                   ||= 0
    self.searchlight_fee                                ||= BigDecimal(0)
    self.setup_fee                                      ||= BigDecimal(0)
    self.terms_accepted                                 ||= nil
    self.text_delay                                     ||= 10
    self.trial_credits                                  ||= BigDecimal(0)
    self.unlimited                                        = self.unlimited.nil? ? false : self.unlimited

    # Client Features
    self.aiagent_message_credits                        ||= 1.0
    self.aiagent_overage_charge                         ||= 25.0
    self.aiagent_included_count                         ||= 0
    self.dlc10_required ||= true
    self.campaigns_count                                ||= 0
    self.custom_fields_count                            ||= 0
    self.folders_count                                  ||= 0
    self.groups_count                                   ||= 0
    self.max_email_templates                            ||= 0
    self.import_contacts_count                          ||= 0
    self.integrations_allowed                           ||= []
    self.max_contacts_count                             ||= 100
    self.max_kpis_count                                 ||= 0
    self.max_users_count                                ||= 1
    self.max_voice_recordings                           ||= 0 # existing
    self.message_central_allowed                          = self.message_central_allowed.nil? ? false : self.message_central_allowed
    self.my_contacts_allowed                              = self.my_contacts_allowed.nil? ? false : self.my_contacts_allowed
    self.my_contacts_group_actions_all_allowed            = self.my_contacts_group_actions_all_allowed.nil? ? false : self.my_contacts_group_actions_all_allowed
    self.phone_call_credits                             ||= BigDecimal(2)
    self.phone_calls_allowed                              = self.phone_calls_allowed.nil? ? false : self.phone_calls_allowed
    self.quick_leads_count                              ||= 0
    self.rvm_allowed                                      = self.rvm_allowed.nil? ? false : self.rvm_allowed
    self.rvm_credits                                    ||= BigDecimal(4)
    self.share_aiagents_allowed                           = self.share_aiagents_allowed.nil? ? false : self.share_aiagents_allowed
    self.share_email_templates_allowed                    = self.share_email_templates_allowed.nil? ? false : self.share_email_templates_allowed
    self.share_funnels_allowed                            = self.share_funnels_allowed.nil? ? false : self.share_funnels_allowed
    self.share_quick_leads_allowed                        = self.share_quick_leads_allowed.nil? ? false : self.share_quick_leads_allowed
    self.share_surveys_allowed                            = self.share_surveys_allowed.nil? ? false : self.share_surveys_allowed
    self.share_widgets_allowed                            = self.share_widgets_allowed.nil? ? false : self.share_widgets_allowed
    self.share_stages_allowed                             = self.share_stages_allowed.nil? ? false : self.share_stages_allowed
    self.stages_count                                   ||= 0
    self.surveys_count                                  ||= 0
    self.tasks_allowed                                    = self.tasks_allowed.nil? ? false : self.tasks_allowed
    self.text_image_credits                             ||= BigDecimal(1)
    self.text_message_credits                           ||= BigDecimal(2)
    self.text_message_images_allowed                      = self.text_message_images_allowed.nil? ? false : self.text_message_images_allowed
    self.text_segment_charge_type                       ||= 2
    self.trackable_links_count                          ||= 0
    self.training                                       ||= []
    self.user_chat_allowed                                = self.user_chat_allowed.nil? ? false : self.user_chat_allowed
    self.video_call_credits                             ||= BigDecimal(3)
    self.video_calls_allowed                              = self.video_calls_allowed.nil? ? false : self.video_calls_allowed
    self.widgets_count                                  ||= 0

    # Client Billing
    self.auto_add_amount                                ||= (BigDecimal(25) / self.credit_charge.to_d).to_i
    self.auto_min_amount                                ||= (BigDecimal(5) / self.credit_charge.to_d).to_i
    self.auto_recharge                                    = self.auto_recharge.nil? ? true : self.auto_recharge
    self.card_brand                                     ||= ''
    self.card_exp_month                                 ||= ''
    self.card_exp_year                                  ||= ''
    self.card_last4                                     ||= ''
    self.card_token                                     ||= ''
    self.client_token                                   ||= ''

    # Task Actions
    self.task_actions                                   ||= {}
    self.task_actions['assigned']                       ||= {}
    self.task_actions['assigned']['campaign_id']        ||= 0
    self.task_actions['assigned']['group_id']           ||= 0
    self.task_actions['assigned']['tag_id']             ||= 0
    self.task_actions['assigned']['stage_id']           ||= 0
    self.task_actions['assigned']['stop_campaign_ids']  ||= []
    self.task_actions['due']                            ||= {}
    self.task_actions['due']['campaign_id']             ||= 0
    self.task_actions['due']['group_id']                ||= 0
    self.task_actions['due']['tag_id']                  ||= 0
    self.task_actions['due']['stage_id'] ||= 0
    self.task_actions['due']['stop_campaign_ids']       ||= []
    self.task_actions['deadline']                       ||= {}
    self.task_actions['deadline']['campaign_id']        ||= 0
    self.task_actions['deadline']['group_id']           ||= 0
    self.task_actions['deadline']['tag_id']             ||= 0
    self.task_actions['deadline']['stage_id']           ||= 0
    self.task_actions['deadline']['stop_campaign_ids']  ||= []
    self.task_actions['completed']                      ||= {}
    self.task_actions['completed']['campaign_id']       ||= 0
    self.task_actions['completed']['group_id']          ||= 0
    self.task_actions['completed']['tag_id']            ||= 0
    self.task_actions['completed']['stage_id']          ||= 0
    self.task_actions['completed']['stop_campaign_ids'] ||= []

    # miscellaneous
    self.contact_phone_labels                         ||= ContactPhone::DEFAULT_LABELS
    self.locked_at                                    ||= nil # record locking activity (for credit card processing to replenish account)

    # Client table fields
    self.tenant                                         = self.tenant.to_s.present? ? self.tenant : I18n.locale.to_s
    self.next_pmt_date                                ||= self.next_payment_date
    self.time_zone                                      = I18n.with_locale(self.tenant) { I18n.t("tenant.#{Rails.env}.time_zone") } if self.new_record? && self.time_zone == 'UTC'

    # ScheduleOnce
    self.scheduleonce_api_key                               ||= ''
    self.scheduleonce_booking_canceled                      ||= 0
    self.scheduleonce_booking_canceled_reschedule_requested ||= 0
    self.scheduleonce_booking_canceled_then_rescheduled     ||= 0
    self.scheduleonce_booking_completed                     ||= 0
    self.scheduleonce_booking_no_show                       ||= 0
    self.scheduleonce_booking_rescheduled                   ||= 0
    self.scheduleonce_booking_scheduled                     ||= 0
    self.scheduleonce_webhook_id                            ||= ''

    # set default User to KEY_USER
    return unless self.def_user_id.to_i.zero? && (key_user = User.find_by(email: I18n.with_locale(self.tenant) { I18n.t("tenant.#{Rails.env}.key_user") }))

    # KEY_USER was found
    self.def_user = key_user
  end

  # delete external resources for Client
  # around_destroy: :destroy_external_resources
  def destroy_external_resources
    # delete phone numbers
    self.twnumbers.each(&:destroy)

    # cancel FirstPromoter payments
    FirstPromoter.new.register_cancellation(client_id: self.id) if self.fp_affiliate.present?

    JsonLog.info 'Client.destroy_external_resources', { message: 'A Client was deleted', client_name: self.name, mo_charge: self.mo_charge }

    yield
  end

  def before_validation_actions
    return if self.destroyed?

    self.state = self.state[0, 2].upcase
    self.phone = self.phone.clean_phone(self.primary_area_code)
  end
end

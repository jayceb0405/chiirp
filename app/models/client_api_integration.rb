# frozen_string_literal: true

# app/models/client_api_integration.rb
class ClientApiIntegration < ApplicationRecord
  belongs_to :client

  store_accessor :data,
                 #  Angi
                 :credentials, :events,
                 # Callrail
                 :credentials, :webhook_api_key, :events, :account_id,
                 # CardX
                 :account, :events, :service_titan, :webhook_api_key, :webhook_header_token, :redirect,
                 # Contractor Commerce
                 :events,
                 # Dope
                 :automations,
                 # DropFunnels
                 :lead_create, :two_step_lead_create, :member_create,
                 :product_purchased_main, :product_purchased_order_bump, :product_purchased_order_upsell, :submit_quiz,
                 # Email
                 :username, :password, :email, :domain, :domain_id, :ips, :mail_cname, :dkim1, :dkim2, :domain_validated, :inbound_username,
                 #  FieldPulse
                 :credentials, :events,
                 #  FieldRoutes
                 :credentials, :events,
                 # Five9
                 :campaigns, :contact_lists, :credentials, :dispositions, :lead_sources, :lists, :text_passthrough,
                 # Google
                 :actions_messages, :actions_reviews, :active_accounts, :active_locations_messages, :active_locations_names, :active_locations_reviews, :agents, :last_start_date, :messages_brand, :review_campaign_ids_excluded, :reviews_links, :user_id,
                 # Housecall Pro general data
                 :credentials,
                 # Housecall Pro (Chiirp) data
                 :company, :custom_fields, :employees, :price_book, :push_leads_tag_id, :webhooks,
                 # InterestRates data
                 :mortgage_rate_updated, :current_mortgage_rates, :mortgage_rate_disclaimer, :mortgage_rate_type_id, :custom_field_id, :differential, :campaign_id, :group_id, :tag_id, :stage_id, :stop_campaign_ids,
                 # Jobber
                 :account, :auth_code, :credentials, :employees, :push_contacts_tag_id, :request_sources, :webhooks,
                 # JobNimbus
                 :push_contacts_tag_id, :webhook_api_key, :webhooks,
                 # Maestro data
                 :api_pass, :salt_responses, :checkin_contact_actions, :checkout_contact_actions, :roommove_contact_actions, :custom_field_assignments,
                 # Maestro & SalesRabbit
                 :new_contact_actions,
                 # Outreach
                 :expires_at, :refresh_token, :token, :users, :webhook_actions,
                 # PC Richard
                 :after_recommendations, :credentials, :custom_fields, :leads, :orders,
                 # ResponsiBid
                 :webhooks, :custom_events,
                 # SalesRabbit data
                 :statuses, :users, :users_users, :status_actions, :last_request_time,
                 # SearchLight
                 :active, :revenue_gen,
                 # SendGrid
                 :email_addresses,
                 # SendJim
                 :push_contacts, :token,
                 # ServiceMonster
                 :account_subtypes, :account_types, :company, :credentials, :custom_fields, :employees, :job_types, :order_groups, :order_subgroups, :price_book, :push_leads_tag_id, :webhooks,
                 # ServiceTitan
                 :booking_fields, :call_event_delay, :credentials, :custom_field_assignments, :customer_custom_fields, :employees, :events, :ignore_sold_with_line_items, :import, :imported_orphaned_estimates_at,
                 :notes, :push_contacts, :tenant_api_key, :update_balance_actions,
                 # ServiceTitan Line Items
                 :categories, :equipment, :line_items, :materials, :services,
                 # Successware
                 :credentials, :employees, :push_contact_tags, :webhooks,
                 # SunbaseData data
                 :sales_rep_id, :appt_setter_id,
                 # Thumbtack
                 :credentials, :events, :auth_code,
                 # Webhooks
                 :webhooks,
                 # Xencall data
                 :live_mode, :channels,
                 :gen_field_id, :gen_field_string, :bu_field_name, :job_field_name, :tech_field_name, :campaign_field_name, :tag_field_name, :desc_field_name

  after_initialize :apply_defaults, if: :new_record?
  before_save :ensure_inbound_username, if: -> { self.target == 'email' && self.inbound_username.nil? }
  before_save :ensure_webhook_api_key, if: -> { self.target == 'contractorcommerce' && self.webhook_api_key.nil? }

  def self.five9_name
    I18n.t('activerecord.models.client_api_integration.five9.title')
  end

  def self.integrations
    %w[
      angi
      callrail
      cardx
      contractorcommerce
      dope
      dropfunnels
      email
      fieldpulse
      fieldroutes
      five9
      housecall
      interest_rates
      jobber
      jobnimbus
      maestro
      outreach
      pcrichard
      responsibid
      salesrabbit
      searchlight
      sendgrid
      sendjim
      servicemonster
      servicetitan
      successware
      sunbasedata
      webhook
      xencall
    ]
  end

  def self.integrations_array
    [
      %w[Angi angi],
      %w[CallRail callrail],
      %w[CardX cardx],
      ['Contractor Commerce', 'contractorcommerce'],
      ['Dope Marketing', 'dope_marketing'],
      %w[DropFunnels dropfunnels],
      %w[Email email],
      %w[FieldPulse fieldpulse],
      %w[FieldRoutes fieldroutes],
      %w[Five9 five9],
      ['HouseCall Pro', 'housecall'],
      ['Interest Rates', 'interest_rates'],
      %w[Jobber jobber],
      %w[JobNimbus jobnimbus],
      %w[Maestro maestro],
      %w[Outreach outreach],
      ['PC Richard', 'pcrichard'],
      %w[ResponsiBid responsibid],
      %w[SalesRabbit salesrabbit],
      %w[SearchLight searchlight],
      %w[SendGrid sendgrid],
      %w[SendJim sendjim],
      %w[ServiceMonster servicemonster],
      %w[ServiceTitan servicetitan],
      %w[Successware successware],
      %w[SunbaseData sunbasedata],
      %w[Thumbtack thumbtack],
      %w[Webhooks webhook],
      %w[Xencall xencall]
    ]
  end

  # update mortgage interest rates for all InterestRate integrations
  # ClientApiIntegration.update_mortgage_interest_rates
  def self.update_mortgage_interest_rates(args = {})
    client_ids = args.include?(:client_id) ? [args[:client_id].to_i] : ClientApiIntegration.where(target: 'interest_rates').pluck(:client_id)

    current_mortgage_rates   = []
    mortgage_rate_disclaimer = ''
    mortgage_rate_updated    = ''

    fred_client  = Integrations::Fred.new
    types_result = fred_client.mortgage_rate_types

    types_result.each do |type|
      rate_result = fred_client.current_mortgage_rate(type: type[:id])

      if fred_client.success?
        current_mortgage_rates << { id: type[:id], title: type[:title], value: rate_result[:value] }
        mortgage_rate_disclaimer  = type[:notes]
        mortgage_rate_updated     = rate_result[:date]
      end
    end

    ClientApiIntegration.where(target: 'interest_rates', client_id: client_ids).find_each do |client_api_integration|
      client_api_integration.update(
        current_mortgage_rates:,
        mortgage_rate_disclaimer:,
        mortgage_rate_updated:
      )

      test_rate = client_api_integration.current_mortgage_rates.filter_map { |rate| rate['id'] == client_api_integration.mortgage_rate_type_id ? rate['value'] : nil }.first

      if test_rate

        client_api_integration.client.contacts
                              .joins(:contact_custom_fields)
                              .where("contact_custom_fields.client_custom_field_id = #{client_api_integration.custom_field_id}")
                              .where("CAST(SUBSTRING(contact_custom_fields.var_value from '(([0-9]+.*)*[0-9]+)') AS float8) - #{test_rate.to_f} > #{client_api_integration.differential.to_f}").find_each do |contact|
          contact.process_actions(
            campaign_id:       client_api_integration.campaign_id,
            group_id:          client_api_integration.group_id,
            stage_id:          client_api_integration.stage_id,
            tag_id:            client_api_integration.tag_id,
            stop_campaign_ids: client_api_integration.stop_campaign_ids
          )
        end
      end
    end
  end

  def attributes_cleaned
    self.attributes.deep_dup.tap do |attributes|
      attributes['data'].delete('credentials')
      attributes['data'].delete('webhook_header_token')
      attributes['data'].delete('password')
      attributes['data'].delete('auth_code')
      attributes['data'].delete('api_pass')
      attributes['data'].delete('salt_responses')
      attributes['data'].delete('token')
      attributes['data'].delete('refresh_token')
      attributes['data'].delete('tenant_api_key')
      attributes['data'].delete('webhook_api_key') if attributes['target'] == 'jobnimbus'
    end
  end

  def valid_outreach_token?
    outreach_client = Integrations::OutReach.new(self.token, self.refresh_token, self.expires_at, self.client.tenant)
    outreach_client.validate_token

    if outreach_client.new_token
      self.update(
        token:         outreach_client.new_token,
        refresh_token: outreach_client.new_refresh_token,
        expires_at:    outreach_client.expires_at
      )
    end

    self.expires_at > 10.minutes.ago.to_i
  end

  private

  def apply_defaults
    case self.target.downcase
    when 'angi'

      case self.name.downcase
      when ''
        self.credentials                                                           ||= { version: '1' }
      when 'events'
        self.events                                                                ||= {}
      end
    when 'callrail'
      self.credentials                                                             ||= {}
      self.credentials['api_key']                                                  ||= ''
      self.credentials['webhook_signature_token']                                  ||= ''
      self.webhook_api_key                                                         ||= SecureRandom.uuid
      self.events                                                                  ||= []
      self.account_id                                                              ||= nil
      self.service_titan                                                           ||= {}
    when 'cardx'
      self.account                                                                 ||= ''
      self.events                                                                  ||= []
      self.webhook_api_key                                                         ||= SecureRandom.uuid
      self.webhook_header_token                                                    ||= RandomCode.new.create(24)
    when 'contractorcommerce'
      self.events                                                                  ||= []
    when 'dope_marketing'
      self.automations                                                             ||= []
    when 'dropfunnels'
      self.lead_create                                                             ||= {}
      self.lead_create['campaign_id']                                              ||= 0
      self.lead_create['group_id']                                                 ||= 0
      self.lead_create['tag_id']                                                   ||= 0
      self.lead_create['stage_id']                                                 ||= 0
      self.two_step_lead_create                                                    ||= {}
      self.two_step_lead_create['campaign_id']                                     ||= 0
      self.two_step_lead_create['group_id']                                        ||= 0
      self.two_step_lead_create['tag_id']                                          ||= 0
      self.two_step_lead_create['stage_id']                                        ||= 0
      self.member_create                                                           ||= {}
      self.member_create['campaign_id']                                            ||= 0
      self.member_create['group_id']                                               ||= 0
      self.member_create['tag_id']                                                 ||= 0
      self.member_create['stage_id']                                               ||= 0
      self.product_purchased_main                                                  ||= {}
      self.product_purchased_main['campaign_id']                                   ||= 0
      self.product_purchased_main['group_id']                                      ||= 0
      self.product_purchased_main['tag_id']                                        ||= 0
      self.product_purchased_main['stage_id']                                      ||= 0
      self.product_purchased_order_bump                                            ||= {}
      self.product_purchased_order_bump['campaign_id']                             ||= 0
      self.product_purchased_order_bump['group_id']                                ||= 0
      self.product_purchased_order_bump['tag_id']                                  ||= 0
      self.product_purchased_order_bump['stage_id']                                ||= 0
      self.product_purchased_order_upsell                                          ||= {}
      self.product_purchased_order_upsell['campaign_id']                           ||= 0
      self.product_purchased_order_upsell['group_id']                              ||= 0
      self.product_purchased_order_upsell['tag_id']                                ||= 0
      self.product_purchased_order_upsell['stage_id']                              ||= 0
      self.submit_quiz                                                             ||= {}
      self.submit_quiz['campaign_id']                                              ||= 0
      self.submit_quiz['group_id']                                                 ||= 0
      self.submit_quiz['tag_id']                                                   ||= 0
      self.submit_quiz['stage_id']                                                 ||= 0
    when 'email'
      self.domain                                                                  ||= ''
      self.domain_id                                                               ||= 0
      self.dkim1                                                                   ||= { 'host' => '', 'data' => '', 'valid' => false, 'reason' => '' }
      self.dkim2                                                                   ||= { 'host' => '', 'data' => '', 'valid' => false, 'reason' => '' }
      self.ips                                                                     ||= ['149.72.26.131']
      self.mail_cname                                                              ||= { 'host' => '', 'data' => '', 'valid' => false, 'reason' => '' }
      self.username                                                                ||= "sg-chiirp-client-#{Rails.env}-#{client.id}"
      self.password                                                                ||= ''
      self.email                                                                   ||= "support+#{self.username}@chiirp.com"
      self.inbound_username                                                        ||= nil
    when 'fieldpulse'
      case self.name.downcase
      when ''
        self.credentials                                                           ||= { version: '1' }
      when 'events'
        self.events                                                                ||= {}
      end
    when 'fieldroutes'

      case self.name.downcase
      when ''
        self.credentials                                                           ||= { auth_key: '', auth_token: '', subdomain: '', version: '1' }
      when 'events'
        self.events                                                                ||= {}
      end
    when 'five9'
      self.campaigns                                                               ||= {}
      self.contact_lists                                                           ||= { book: '', create: '', update: '' }
      self.credentials                                                             ||= { password: '', username: '', version: Integration::Five9::Base::CURRENT_VERSION }
      self.dispositions                                                            ||= []
      self.lead_sources                                                            ||= []
      self.lists                                                                   ||= {}
      self.text_passthrough                                                          = self.text_passthrough.nil? ? false : self.text_passthrough
    when 'google'
      self.actions_messages                                                        ||= {}
      self.actions_reviews                                                         ||= { '1' => {}, '2' => {}, '3' => {}, '4' => {}, '5' => {} }
      self.active_accounts                                                         ||= []
      self.active_locations_messages                                               ||= {}
      self.active_locations_names                                                  ||= {}
      self.active_locations_reviews                                                ||= {}
      self.agents                                                                  ||= []
      self.last_start_date                                                         ||= ''
      self.review_campaign_ids_excluded                                            ||= []
      self.reviews_links                                                           ||= {}
      self.user_id                                                                 ||= 0
    when 'housecall'
      # Housecall Pro (Chiirp) data
      self.company                                                                 ||= {}
      self.credentials                                                             ||= { access_token: '', access_token_expires_at: 0, refresh_token: '' }
      self.custom_fields                                                           ||= {}
      self.employees                                                               ||= {}
      self.price_book                                                              ||= {}
      self.push_leads_tag_id                                                       ||= 0
      self.webhooks                                                                ||= {}
    when 'interest_rates'
      # Interest Rates
      self.mortgage_rate_updated                                                   ||= 'N/A'
      self.current_mortgage_rates                                                  ||= []
      self.mortgage_rate_disclaimer                                                ||= ''
      self.mortgage_rate_type_id                                                   ||= 'MORTGAGE30US'
      self.custom_field_id                                                         ||= 0
      self.differential                                                            ||= 0.0
      self.campaign_id                                                             ||= 0
      self.group_id                                                                ||= 0
      self.tag_id                                                                  ||= 0
      self.stage_id                                                                ||= 0
    when 'jobber'
      self.account                                                                 ||= {}
      self.auth_code                                                               ||= ''
      self.credentials                                                             ||= {}
      self.employees                                                               ||= {}
      self.push_contacts_tag_id                                                    ||= 0
      self.request_sources                                                         ||= []
      self.webhooks                                                                ||= {}
    when 'jobnimbus'
      case self.name.downcase
      when ''
        if self.api_key.blank?
          self.webhook_api_key = SecureRandom.uuid
          self.webhook_api_key = SecureRandom.uuid while UserApiIntegration.where(target: 'jobnimbus').find_by('data @> ?', { webhook_api_key: self.webhook_api_key }.to_json)
        end

        self.push_contacts_tag_id                                                    ||= 0
        self.webhooks                                                                ||= {}
      when 'sales_reps'
        self.data                                                                    ||= {}
      else
        self.data                                                                    ||= []
      end
    when 'maestro'
      # Maestro data
      self.api_pass                                                                ||= '' # Pass
      self.salt_responses                                                          ||= {}
      self.new_contact_actions                                                     ||= {}
      self.checkin_contact_actions                                                 ||= {}
      self.checkout_contact_actions                                                ||= {}
      self.roommove_contact_actions                                                ||= {}
      self.custom_field_assignments                                                ||= {}
    when 'outreach'
      self.refresh_token                                                           ||= ''
      self.token                                                                   ||= ''
      self.expires_at                                                              ||= 0
      self.users                                                                   ||= {}
      self.webhook_actions                                                         ||= []

      if self.api_key.blank?
        self.api_key = RandomCode.new.create(36)
        self.api_key = RandomCode.new.create(36) while UserApiIntegration.find_by(target: 'outreach', api_key: self.api_key)
      end
    when 'pcrichard'
      if self.api_key.blank?
        self.api_key = SecureRandom.uuid
        self.api_key = SecureRandom.uuid while ClientApiIntegration.find_by(target: 'pcrichard', api_key: self.api_key)
      end

      self.after_recommendations                                                   ||= {}
      self.credentials                                                             ||= { auth_token: '' }
      self.custom_fields                                                           ||= {}
      self.leads                                                                   ||= {}
      self.orders                                                                  ||= {}
    when 'responsibid'
      if self.api_key.blank?
        self.api_key = SecureRandom.uuid
        self.api_key = SecureRandom.uuid while UserApiIntegration.find_by(target: 'responsibid', api_key: self.api_key)
      end

      self.webhooks                                                                ||= {}
      self.custom_events                                                           ||= []
    when 'salesrabbit'
      # SalesRabbit data
      self.statuses                                                                ||= []
      self.users                                                                   ||= []
      self.users_users                                                             ||= {}
      self.status_actions                                                          ||= {}
      self.new_contact_actions                                                     ||= {}
      self.last_request_time                                                       ||= ''
    when 'searchlight'
      self.active                                                                  ||= false
      self.revenue_gen                                                             ||= {}
    when 'sendgrid'
      # SendGrid data
      self.email_addresses                                                         ||= []
    when 'sendjim'
      # SendJim data
      self.push_contacts                                                           ||= []
      self.token                                                                   ||= ''
    when 'servicemonster'
      # ServiceMonster data
      self.account_subtypes                                                        ||= []
      self.account_types                                                           ||= []
      self.company                                                                 ||= {}
      self.credentials                                                             ||= {}
      self.custom_fields                                                           ||= {}
      self.employees                                                               ||= {}
      self.job_types                                                               ||= []
      self.order_groups                                                            ||= []
      self.order_subgroups                                                         ||= []
      self.price_book                                                              ||= {}
      self.push_leads_tag_id                                                       ||= 0
      self.refresh_token                                                           ||= ''
      self.webhooks                                                                ||= {}
    when 'servicetitan'

      case self.name.downcase
      when ''
        # ServiceTitan data
        self.booking_fields                                                          ||= {}
        self.call_event_delay                                                        ||= 60
        self.credentials                                                             ||= { app_id: '02', client_id: '', client_secret: '', access_token: '', access_token_expires: 0, tenant_id: '' }
        self.custom_field_assignments                                                ||= {}
        self.customer_custom_fields                                                  ||= {}
        self.employees                                                               ||= {}
        self.ignore_sold_with_line_items                                             ||= []
        self.import                                                                  ||= {}
        self.import['campaign_id_0']                                                 ||= 0
        self.import['group_id_0']                                                    ||= 0
        self.import['tag_id_0']                                                      ||= 0
        self.import['stage_id_0']                                                    ||= 0
        self.import['campaign_id_above_0']                                           ||= 0
        self.import['group_id_above_0']                                              ||= 0
        self.import['tag_id_above_0']                                                ||= 0
        self.import['stage_id_above_0']                                              ||= 0
        self.import['campaign_id_below_0']                                           ||= 0
        self.import['group_id_below_0']                                              ||= 0
        self.import['tag_id_below_0']                                                ||= 0
        self.import['stage_id_below_0']                                              ||= 0
        self.imported_orphaned_estimates_at                                          ||= 15.days.ago.iso8601
        self.events                                                                  ||= {}
        self.notes                                                                   ||= {}
        self.push_contacts                                                           ||= []
        self.tenant_api_key                                                          ||= ''
        self.update_balance_actions                                                  ||= {}
        self.update_balance_actions['campaign_id_0']                                 ||= 0
        self.update_balance_actions['group_id_0']                                    ||= 0
        self.update_balance_actions['tag_id_0']                                      ||= 0
        self.update_balance_actions['stage_id_0']                                    ||= 0
        self.update_balance_actions['campaign_id_decrease']                          ||= 0
        self.update_balance_actions['group_id_decrease']                             ||= 0
        self.update_balance_actions['tag_id_decrease']                               ||= 0
        self.update_balance_actions['stage_id_decrease']                             ||= 0
        self.update_balance_actions['campaign_id_increase']                          ||= 0
        self.update_balance_actions['group_id_increase']                             ||= 0
        self.update_balance_actions['tag_id_increase']                               ||= 0
        self.update_balance_actions['stage_id_increase']                             ||= 0
        self.update_balance_actions['update_invoice_window_days']                    ||= 0
        self.update_balance_actions['update_balance_window_days']                    ||= 0
        self.update_balance_actions['update_open_estimate_window_days']              ||= 15
      when 'line_items'
        self.categories                                                              ||= []
        self.equipment                                                               ||= false
        self.line_items                                                              ||= {}
        self.materials                                                               ||= false
        self.services                                                                ||= false
      end
    when 'successware'

      case self.name.downcase
      when ''
        if self.api_key.blank?
          self.api_key = SecureRandom.uuid
          self.api_key = SecureRandom.uuid while ClientApiIntegration.find_by(target: 'successware', api_key: self.api_key)
        end

        self.credentials                                                             ||= {}
        self.employees                                                               ||= {}
        self.push_contact_tags                                                       ||= []
        self.webhooks                                                                ||= {}
      end
    when 'sunbasedata'
      self.sales_rep_id                                                            ||= ''
      self.appt_setter_id                                                          ||= ''
    when 'thumbtack'
      self.credentials                                                             ||= {}
      self.events                                                                  ||= []
      self.auth_code                                                               ||= SecureRandom.uuid
    when 'webhook'
      self.webhooks                                                                ||= {}
    when 'xencall'
      # Xencall data
      self.live_mode                                                               ||= 0
      self.channels                                                                ||= []
      self.gen_field_id                                                            ||= ''
      self.gen_field_string                                                        ||= ''
      self.bu_field_name                                                           ||= ''
      self.job_field_name                                                          ||= ''
      self.tech_field_name                                                         ||= ''
      self.campaign_field_name                                                     ||= ''
      self.tag_field_name                                                          ||= ''
      self.desc_field_name                                                         ||= ''
    end
  end

  # ensure record has an inbound_username and it is unique
  def ensure_inbound_username
    self.inbound_username = RandomCode.new.easy_alphanumeric
    self.inbound_username = RandomCode.new.easy_alphanumeric until ClientApiIntegration.where(target: 'email').where('data->>\'inbound_username\' = ?', self.inbound_username).empty?
  end

  def ensure_webhook_api_key
    self.webhook_api_key = RandomCode.new.create(32)
    self.webhook_api_key = RandomCode.new.create(32) until ClientApiIntegration.where(target: 'contractorcommerce').where('data->>\'webhook_api_key\' = ?', self.webhook_api_key).empty?
  end
end
